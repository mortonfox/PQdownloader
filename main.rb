require_relative 'token_file'
require 'getoptlong'

USAGE = <<-EOM
Usage: #{$0} [OPTION]...

Options:
  -h, --help:
      Show help.

  -l, --login:
      Ignore saved token and force a login.
EOM

force_login = false

begin

  opts = GetoptLong.new( 
                        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
                        [ '--login', '-l', GetoptLong::NO_ARGUMENT ], 
                       )

  opts.each { |opt, arg|
    case opt

    when '--help'
      puts USAGE
      exit 0

    when '--login'
      force_login = true

    end
  }

rescue => err
  $stderr.puts USAGE
  exit 1
end

access_token = PQDownloader::TokenFile.new.get_token force_login
puts "Access Token = #{access_token}"

