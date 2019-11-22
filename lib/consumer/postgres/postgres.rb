module Consumer
  module Postgres
    Error = Class.new(RuntimeError)

    def self.included(cls)
      cls.class_exec do
        include ::Consumer

        attr_accessor :batch_size
        attr_accessor :correlation
        attr_accessor :group_member
        attr_accessor :group_size
        attr_accessor :condition
      end
    end

    def starting
      unless batch_size.nil?
        logger.info(tag: :*) { "Batch Size: #{batch_size}" }
      end

      unless correlation.nil?
        logger.info(tag: :*) { "Correlation: #{correlation}" }
      end

      unless group_member.nil? && group_size.nil?
        logger.info(tag: :*) { "Group Member: #{group_member.inspect}, Group Size: #{group_size.inspect}" }
      end

      unless condition.nil?
        logger.info(tag: :*) { "Condition: #{condition}" }
      end
    end

    def configure(batch_size: nil, settings: nil, correlation: nil, group_member: nil, group_size: nil, condition: nil)
      if not MessageStore::StreamName.category?(stream_name)
        raise Error, "Consumer's stream name must be a category (Stream Name: #{stream_name})"
      end

      self.batch_size = batch_size
      self.correlation = correlation
      self.group_member = group_member
      self.group_size = group_size
      self.condition = condition

      MessageStore::Postgres::Session.configure(self, settings: settings)

      session = self.session

      PositionStore.configure(
        self,
        stream_name,
        consumer_identifier: identifier,
        session: session
      )

      get_session = MessageStore::Postgres::Session.build(settings: settings)

      MessageStore::Postgres::Get.configure(
        self,
        stream_name,
        batch_size: batch_size,
        correlation: correlation,
        consumer_group_member: group_member,
        consumer_group_size: group_size,
        condition: condition,
        session: get_session
      )
    end
  end
end
