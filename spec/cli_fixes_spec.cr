# spec/cli_fixes_spec.cr
#
# Regression specs for the pre-1.0 CLI bug sweep on fix-pre1.0-bugs:
#
#   - sign.cr: password masking in command echo, numeric build-tools
#     version ordering, shell-free execution
#   - create.cr: project name validation (path traversal), template
#     validation, crystal version extraction for the generated shard.yml
#
# Pure helpers only — no command execution, no device, no network.

require "./spec_helper"

describe "SignUtil.redact" do
  it "masks keystore and key passwords" do
    cmd = [
      "/opt/sdk/build-tools/34.0.0/apksigner",
      "sign",
      "--ks", "/home/user/My Keys/debug.keystore",
      "--ks-key-alias", "androiddebugkey",
      "--ks-pass", "pass:secret-store-pw",
      "--key-pass", "pass:secret-key-pw",
      "--out", "/home/user/My Keys/app.apk",
      "/home/user/My Keys/app-unsigned.apk",
    ]

    rendered = Native::CLI::SignUtil.redact(cmd)

    rendered.should_not contain("secret-store-pw")
    rendered.should_not contain("secret-key-pw")
    rendered.should contain("pass:***")
    rendered.should contain("/home/user/My Keys/debug.keystore")
  end

  it "leaves commands without passwords untouched" do
    Native::CLI::SignUtil.redact(["apksigner", "verify", "app.apk"])
      .should eq("apksigner verify app.apk")
  end
end

describe "SignUtil.build_tools_version_key" do
  it "orders versions numerically, not lexicographically" do
    key_9 = Native::CLI::SignUtil.build_tools_version_key("9.0.0")
    key_34 = Native::CLI::SignUtil.build_tools_version_key("34.0.0")

    # String sort used to pick 9.0.0 over 34.0.0 ("9" > "3").
    (key_9 < key_34).should be_true
  end

  it "compares multi-part versions element-wise" do
    a = Native::CLI::SignUtil.build_tools_version_key("33.0.2")
    b = Native::CLI::SignUtil.build_tools_version_key("33.1.0")

    (a < b).should be_true
  end

  it "treats non-numeric segments as zero" do
    key = Native::CLI::SignUtil.build_tools_version_key("rc-5")
    key.should eq([5])
  end
end

describe "CreateUtil.valid_project_name?" do
  it "accepts ordinary project names" do
    Native::CLI::CreateUtil.valid_project_name?("my_app").should be_true
    Native::CLI::CreateUtil.valid_project_name?("MyApp").should be_true
    Native::CLI::CreateUtil.valid_project_name?("app-2").should be_true
  end

  it "rejects path traversal and separators" do
    # The name becomes a directory path — ../evil used to escape the cwd.
    Native::CLI::CreateUtil.valid_project_name?("../evil").should be_false
    Native::CLI::CreateUtil.valid_project_name?("a/b").should be_false
    Native::CLI::CreateUtil.valid_project_name?("/etc").should be_false
    Native::CLI::CreateUtil.valid_project_name?("..").should be_false
    Native::CLI::CreateUtil.valid_project_name?(".").should be_false
  end

  it "rejects empty and whitespace names" do
    Native::CLI::CreateUtil.valid_project_name?("").should be_false
    Native::CLI::CreateUtil.valid_project_name?("my app").should be_false
  end

  it "rejects names that would break the generated Crystal code" do
    Native::CLI::CreateUtil.valid_project_name?("2fast").should be_false
    Native::CLI::CreateUtil.valid_project_name?("my-app!").should be_false
  end
end

describe "CreateUtil.known_template?" do
  it "accepts the implemented templates" do
    Native::CLI::CreateUtil.known_template?("app").should be_true
    Native::CLI::CreateUtil.known_template?("game").should be_true
  end

  it "rejects advertised-but-unimplemented and bogus templates" do
    # "library" is listed in the old help text but silently built the app
    # template; bogus names were accepted silently too.
    Native::CLI::CreateUtil.known_template?("library").should be_false
    Native::CLI::CreateUtil.known_template?("banana").should be_false
  end
end

describe "CreateUtil.extract_crystal_version" do
  it "extracts the version from real `crystal --version` output" do
    # The raw first line used to be written into shard.yml verbatim,
    # producing `crystal: ">= Crystal 1.20.0 [c7d6de74b] (2026-04-16)"`.
    raw = "Crystal 1.20.0 [c7d6de74b] (2026-04-16)"
    Native::CLI::CreateUtil.extract_crystal_version(raw).should eq("1.20.0")
  end

  it "handles plain version output" do
    Native::CLI::CreateUtil.extract_crystal_version("Crystal 1.9.2").should eq("1.9.2")
  end

  it "returns nil when crystal is not installed" do
    Native::CLI::CreateUtil.extract_crystal_version("").should be_nil
  end

  it "returns nil for unparseable output" do
    Native::CLI::CreateUtil.extract_crystal_version("sh: crystal: command not found").should be_nil
  end
end
