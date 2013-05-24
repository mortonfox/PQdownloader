require 'oauth'
require 'webrick'
require 'thread'
require 'cgi'

require_relative 'config'

# oauth_body_hash field in OAuth header is disallowed when requesting an
# access token from Groundspeak API.
class Net::HTTPGenericRequest
  def oauth_body_hash_required?
    false
  end
end


module PQDownloader

  class GCOAuth

    def initialize
      @config = Config.new      
    end

    def login
      oauth = OAuth::Consumer.new(@config.consumer_key, @config.consumer_secret, 
                                  { :site => 'https://staging.geocaching.com/OAuth/oauth.ashx' })
      oauth.http.set_debug_output $stdout if $DEBUG
      request_token = oauth.get_request_token :oauth_callback => "http://#{@config.callback_host}:#{@config.callback_port}/oauth"

      oauth_result = {}

      log = if $DEBUG
              WEBrick::Log.new $stderr, WEBrick::Log::DEBUG
            else
              WEBrick::Log.new $stdout, WEBrick::Log::ERROR
            end

      access_log = if $DEBUG
                     [ [ $stdout, WEBrick::AccessLog::COMBINED_LOG_FORMAT ] ]
                   else
                     []
                   end

      server = WEBrick::HTTPServer.new :Port => @config.callback_port, :Logger => log, :AccessLog => access_log
      server.mount_proc '/oauth' do |req, res|
        oauth_result = CGI::parse req.query_string
        res.body = <<-EOM
<!DOCTYPE html>
<html>
  <body>
    Logged in.
  </body>
</html>
        EOM
        server.shutdown
      end

      server.mount_proc '/favicon.ico' do |req, res|
        res.status = 404
      end

      thr = Thread.new {
        server.start
      }

      system "open #{request_token.authorize_url}"

      # Wait for user to authorize us.
      thr.join

      oauth_verifier = oauth_result['oauth_verifier'].first
      access_token = request_token.get_access_token :oauth_verifier => oauth_verifier

      access_token.token
    end

  end

end

if __FILE__ == $0
  access_token = PQDownloader::GCOAuth.new.login
  puts "Access Token = #{access_token}"
end
