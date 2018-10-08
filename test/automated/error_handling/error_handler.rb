require_relative '../automated_init'

context "Error Handling" do
  context "Error Handler Given" do
    consumer = Controls::Consumer::ErrorHandler.example

    message_data = Controls::MessageData.example

    context "Dispatch fails" do
      test "Error is not raised" do
        refute proc { consumer.dispatch(message_data) } do
          raises_error? Controls::Error::Example
        end
      end

      test "Error is handled" do
        assert(consumer.handled_error?)
      end

      test "Message data is passed to error handler" do
        assert(consumer.failed_message?(message_data))
      end
    end
  end
end
