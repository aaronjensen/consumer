module Consumer
  class Subscription
    include ::Actor

    ::Configure.activate(self)

    include Log::Dependency

    configure :subscription

    initializer :stream_name, :get

    attr_accessor :next_batch

    attr_writer :position
    def position
      @position ||= 0
    end

    dependency :poll, Poll

    def self.build(stream_name, get, position: nil, poll_interval_milliseconds: nil)
      poll_interval_milliseconds ||= Defaults.poll_interval_milliseconds
      poll_timeout_milliseconds = Defaults.poll_timeout_milliseconds

      instance = new(stream_name, get)

      instance.position = position

      Poll.configure(
        instance,
        interval_milliseconds: poll_interval_milliseconds,
        timeout_milliseconds: poll_timeout_milliseconds
      )

      instance.configure
      instance
    end

    handle :start do
      :resupply
    end

    handle :resupply do
      logger.trace { "Resupplying (StreamName: #{stream_name}, Position: #{position})" }

      batch = poll.() do
        get.(stream_name, position: position)
      end

      if batch.nil? || batch.empty?
        logger.debug { "Did not resupply; no events available (StreamName: #{stream_name}, Position: #{position})" }

        :resupply
      else
        self.next_batch = batch

        logger.debug { "Resupplied (StreamName: #{stream_name}, Position: #{position}, Batch Size: #{batch.count})" }
      end
    end

    handle :get_batch do |get_batch|
      logger.trace { "Batch request received" }

      if next_batch.nil?
        logger.debug { "Could not fulfill batch request; deferring" }

        return get_batch
      end

      batch = reset_next_batch

      reply_message = get_batch.reply_message(batch)

      send.(reply_message, get_batch.reply_address)

      logger.debug { "Batch request fulfilled; resupplying (Batch Size: #{batch.count})" }

      :resupply
    end

    def reset_next_batch
      batch = next_batch

      self.next_batch = nil

      self.position = batch.last.global_position + 1

      batch
    end
  end
end
