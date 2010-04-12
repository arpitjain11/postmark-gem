require 'spec_helper'

describe "Bounce" do
  let(:bounce_json) { %{{"Type":"HardBounce","TypeCode":1,"Details":"test bounce","Email":"jim@test.com","BouncedAt":"#{Time.now.to_s}","DumpAvailable":true,"Inactive":false,"CanActivate":true,"ID":12}} }
  let(:bounces_json) { "[#{bounce_json},#{bounce_json}]" }

  context "single bounce" do
    let(:bounce) { Postmark::Bounce.find(12) }

    before do
      Timecop.freeze
      FakeWeb.register_uri(:get, "http://api.postmarkapp.com/bounces/12", { :body => bounce_json })
    end

    after do
      Timecop.return
    end

    it "should retrieve and parce bounce correctly" do
      bounce.type.should == "HardBounce"
      bounce.bounced_at.should == Time.now
      bounce.details.should == "test bounce"
      bounce.email.should == "jim@test.com"
    end

    it "should retrieve bounce dump" do
      FakeWeb.register_uri(:get, "http://api.postmarkapp.com/bounces/12/dump", { :body => %{{"Body": "Some SMTP gibberish"}} } )
      bounce.dump.should == "Some SMTP gibberish"
    end

  end

  it "should retrieve bounces" do
    FakeWeb.register_uri(:get, "http://api.postmarkapp.com/bounces?count=30&offset=0", { :body => bounces_json })
    bounces = Postmark::Bounce.all
    bounces.should have(2).entries
    bounces[0].should be_a(Postmark::Bounce)
  end
end