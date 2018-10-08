module Consumer
  class Actor
    include ::Actor
    include Log::Dependency

    initializer :subscription_address

    dependency :consumer, Consumer

    def self.build(consumer, subscription)
      instance = new subscription.address
      instance.consumer = consumer
      instance.configure
      instance
    end

    handle :start do
      request_batch
    end

    handle Subscription::GetBatch::Reply do |get_batch_reply|
      messages = get_batch_reply.batch

      logger.trace { "Received batch (Messages: #{messages.count})" }

      request_batch

      messages.each do |message_data|
        consumer.dispatch(message_data)
      end

      logger.debug { "Batch received (Events: #{messages.count})" }
    end

    def request_batch
      logger.trace { "Requesting batch" }

      get_batch = Subscription::GetBatch.new(address)

      send.(get_batch, subscription_address)

      logger.debug { "Send batch request" }
    end
  end
end
