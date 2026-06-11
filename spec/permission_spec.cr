# spec/permissions_spec.cr

require "./spec_helper"

describe Native::Permissions::PermissionType do
  it "has all permission types" do
    Native::Permissions::PermissionType::Camera.should be_a(Native::Permissions::PermissionType)
    Native::Permissions::PermissionType::Microphone.should be_a(Native::Permissions::PermissionType)
    Native::Permissions::PermissionType::Location.should be_a(Native::Permissions::PermissionType)
    Native::Permissions::PermissionType::Notifications.should be_a(Native::Permissions::PermissionType)
    Native::Permissions::PermissionType::Storage.should be_a(Native::Permissions::PermissionType)
  end
end

describe Native::Permissions::PermissionStatus do
  it "has all status values" do
    Native::Permissions::PermissionStatus::Granted.should be_a(Native::Permissions::PermissionStatus)
    Native::Permissions::PermissionStatus::Denied.should be_a(Native::Permissions::PermissionStatus)
    Native::Permissions::PermissionStatus::Restricted.should be_a(Native::Permissions::PermissionStatus)
    Native::Permissions::PermissionStatus::NotDetermined.should be_a(Native::Permissions::PermissionStatus)
  end
end
