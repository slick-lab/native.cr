# spec/push_notification_spec.cr

require "./spec_helper"

describe Native::PushNotifications::Message do
  it "carries title, body and payload" do
    msg = Native::PushNotifications::Message.new("Hello", "World", %({"from": "server"}))
    msg.title.should eq("Hello")
    msg.body.should eq("World")
    msg.payload.should eq(%({"from": "server"}))
  end
end

describe Native::PushNotifications do
  it "dispatches on_message callbacks" do
    received = nil
    Native::PushNotifications.on_message do |msg|
      received = msg
    end
    Native::PushNotifications.handle_message_received("Title", "Body", "{}")
    received.should_not be_nil
    received.not_nil!.title.should eq("Title")
    received.not_nil!.body.should eq("Body")
  end

  it "dispatches on_tap callbacks with payload and id" do
    tapped_payload = nil
    tapped_id = 0
    Native::PushNotifications.on_tap do |payload, id|
      tapped_payload = payload
      tapped_id = id
    end
    Native::PushNotifications.handle_notification_tapped(%({"screen": "inbox"}), 42)
    tapped_payload.should eq(%({"screen": "inbox"}))
    tapped_id.should eq(42)
  end

  it "dispatches token callbacks" do
    token = nil
    Native::PushNotifications.on_token do |t|
      token = t
    end
    Native::PushNotifications.handle_token_ready("abc123")
    token.should eq("abc123")
  end

  it "dispatches token refresh callbacks" do
    refreshed = nil
    Native::PushNotifications.on_token_refresh do |t|
      refreshed = t
    end
    Native::PushNotifications.handle_token_refresh("rotated")
    refreshed.should eq("rotated")
  end

  it "survives callbacks that raise" do
    raised = false
    Native::PushNotifications.on_message do |_msg|
      raised = true
      raise "user code exploded"
    end
    Native::PushNotifications.handle_message_received("T", "B", "{}")
    raised.should be_true
  end

  it "resolves permission without blocking on desktop" do
    granted = nil
    Native::PushNotifications.request_permission do |g|
      granted = g
    end
    granted.should eq(true)
  end

  it "returns the desktop placeholder token" do
    token = nil
    Native::PushNotifications.get_token do |t|
      token = t
    end
    token.should eq("desktop-no-token")
  end
end
