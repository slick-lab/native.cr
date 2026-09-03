# spec/version_util_spec.cr
#
# Edge cases for the doctor command's version comparison. Release tags on
# GitHub are "v"-prefixed while Native::VERSION is bare, and unparseable
# strings must degrade to nil instead of blowing up the update check.

require "./spec_helper"

describe Native::CLI::VersionUtil do
  it "reports equal versions as zero" do
    Native::CLI::VersionUtil.compare("0.1.6", "0.1.6").should eq(0)
  end

  it "detects an outdated install" do
    Native::CLI::VersionUtil.compare("0.1.6", "0.2.0").should eq(-1)
  end

  it "detects a development version ahead of the latest release" do
    Native::CLI::VersionUtil.compare("0.3.0", "0.2.0").should eq(1)
  end

  it "tolerates a v-prefixed tag (the case that broke the old inline check)" do
    Native::CLI::VersionUtil.compare("0.1.6", "v0.2.0").should eq(-1)
    Native::CLI::VersionUtil.compare("0.1.6", "v0.1.6").should eq(0)
    Native::CLI::VersionUtil.compare("0.2.0", "v0.1.6").should eq(1)
  end

  it "tolerates a V-prefixed tag and surrounding whitespace" do
    Native::CLI::VersionUtil.compare(" V0.1.6 ", " 0.1.6 ").should eq(0)
  end

  it "ignores build metadata on either side" do
    Native::CLI::VersionUtil.compare("1.0.0+build.5", "1.0.0").should eq(0)
    Native::CLI::VersionUtil.compare("1.0.0", "1.0.0+build.5").should eq(0)
  end

  it "orders a release above its prereleases like semver says" do
    Native::CLI::VersionUtil.compare("1.0.0", "1.0.0-rc.1").should eq(1)
    Native::CLI::VersionUtil.compare("1.0.0-alpha", "1.0.0-rc.1").should eq(-1)
    Native::CLI::VersionUtil.compare("1.0.0-rc.1", "1.0.0-rc.1").should eq(0)
  end

  it "returns nil for unparseable input instead of raising" do
    Native::CLI::VersionUtil.compare("banana", "1.0.0").should be_nil
    Native::CLI::VersionUtil.compare("1.0.0", "").should be_nil
    Native::CLI::VersionUtil.compare("1.0.0", "v").should be_nil
    Native::CLI::VersionUtil.compare("1.0.0", "1.2").should be_nil
    Native::CLI::VersionUtil.compare("vv1.0.0", "1.0.0").should be_nil
  end
end
