require 'spec_helper'
require 'nagios_parser/status/parser'

describe NagiosParser::Status::Parser do
  let(:parser) { NagiosParser::Status::Parser.new }

  describe ".parse" do
    it "returns a hash of status types" do
      data = parser.parse('info { version=3.2.0 }')
      data['info'].first['version'].should == '3.2.0'
    end
  end

  describe "#create_token" do
    context "given a valid string" do
      it "creates a valid token list" do
        string = <<-RUBY
          hoststatus {
            bar=baz
            hello = world
            foo= bar
            foo = bar baz hello world
            eek = 1
          }
          info { version=3.2.0 }

          servicestatus {
            service_description=POP3S
            plugin_output=POP OK - 0.062 second response time on port 995 [+OK Dovecot ready. <123.456@example.com>]
          }

          programstatus {
            last_command_check=1291408262
            global_service_event_handler=
                                   }
        RUBY

        parser.create_token(string).should == [
          [:TYPE, 'hoststatus'],
          [:OPEN, nil],
          [:KEY, 'bar'], [:VALUE, 'baz'],
          [:KEY, 'hello'], [:VALUE, 'world'],
          [:KEY, 'foo'], [:VALUE, 'bar'],
          [:KEY, 'foo'], [:VALUE, 'bar baz hello world'],
          [:KEY, 'eek'], [:VALUE, 1],
          [:CLOSE, nil],
          [:TYPE, 'info'],
          [:OPEN, nil],
          [:KEY, 'version'], [:VALUE, '3.2.0'],
          [:CLOSE, nil],
          [:TYPE, 'servicestatus'],
          [:OPEN, nil],
          [:KEY, 'service_description'], [:VALUE, 'POP3S'],
          [:KEY, 'plugin_output'], [:VALUE, 'POP OK - 0.062 second response time on port 995 [+OK Dovecot ready. <123.456@example.com>]'],
          [:CLOSE, nil],
          [:TYPE, 'programstatus'],
          [:OPEN, nil],
          [:KEY, 'last_command_check'], [:VALUE, 1291408262],
          [:KEY, 'global_service_event_handler'],
          [:CLOSE, nil],
          [false, false]
        ]
      end
    end
  end

  describe "#next_token" do
    it "returns shifts the next element off the token list" do
      parser.token = [:one, :two, :three]
      parser.next_token
      parser.next_token.should == :two
    end
  end

  describe "#parse" do
    context "with a valid string" do
      it "returns a hash of status types" do
        string = <<-RUBY
          hoststatus {
            bar=baz
            hello = world
            version = 1
          }
          info { version=3.2.0 }

          program {
              version=2.x.x
                                   }
        RUBY

        data = parser.parse(string)
        data['info'].first['version'].should == '3.2.0'
        data['hoststatus'].first['bar'].should == 'baz'
        data['hoststatus'].first['version'].should == 1
        data['program'].first['version'].should == '2.x.x'
      end
    end

    context "with a valid string containing squiggly braces" do
      it "returns a hash of status types" do
        string = <<-RUBY
          servicestatus {
            check_command=check_http_api!api.example.com!80!'{"status":true}'
          }
        RUBY

        data = parser.parse(string)
      end
    end

    context "with invalid status data" do
      it "will raise an exception" do
        expect {
          parser.parse('info { =test }')
        }.to raise_error
      end
    end
  end
end
