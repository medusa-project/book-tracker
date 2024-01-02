require 'test_helper'
require 'aws-sdk-sqs'
require "aws-sdk-sts"

class RecordSourceTest < ActiveSupport::TestCase
  test "sends a message sqs" do 
    record_source = RecordSource.new 

    sqs = Aws::SQS::Client.new(region: 'us-east-2')
    queue_name = "book-tracker-demo"
    queue_url = sqs.get_queue_url(queue_name: queue_name).queue_url
    message = {status: "Record has been updated"}
    sqs.send_message({queue_url: queue_url, 
      message_body: message.to_json})
    
    assert_equal message, {"status":"Record has been updated"}
  end
end
