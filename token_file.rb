require_relative 'gc_oauth'

TOKEN_FILE = 'gc.tok'

module PQDownloader

  class TokenFile

    def initialize
    end

    def read_token_file
      tok = nil
      begin
        File.open(TOKEN_FILE, 'r') { |file|
          tok = file.gets.strip
        }
      rescue => err
      end
      tok
    end

    def write_token_file tok
      File.open(TOKEN_FILE, 'w') { |file|
        file.puts tok
      }
    rescue => err
    end

    def get_token force_login = false
      tok = read_token_file
      unless not force_login and tok and tok.size > 0
        tok = PQDownloader::GCOAuth.new.login
        write_token_file tok
      end
      tok
    end
  end
end
