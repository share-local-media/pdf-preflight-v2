require File.dirname(__FILE__) + "/../spec_helper"

class InstanceRuleProfile
  include Preflight::Profile

  profile_name "custom"
end

describe InstanceRuleProfile do

  it "correctly pass a valid file when no rules are defined" do
    filename  = pdf_spec_file("version_1_4")
    preflight = InstanceRuleProfile.new
    messages  = preflight.check(filename)

    messages.should be_empty
  end

  it "correctly fail a file that doesn't pass a rule added to the profile instance" do
    filename  = pdf_spec_file("version_1_4")
    preflight = InstanceRuleProfile.new
    preflight.rule Preflight::Rules::MaxVersion, 1.3
    messages  = preflight.check(filename)

    messages.should_not be_empty
  end

end
