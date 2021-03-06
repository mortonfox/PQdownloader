require_relative 'token_file'
require 'getoptlong'
require 'uri'
require 'net/http'
require 'net/https'
require 'json'
require 'time'
require 'base64'


GC_API_ROOT = 'https://staging.api.groundspeak.com/Live/V6Beta/geocaching.svc'

def call_gc svcname, access_token, parms = {}
  uri = URI "#{GC_API_ROOT}/#{svcname}"
  uri.query = URI.encode_www_form parms.merge(
    :format => 'json', 
    :accessToken => access_token
  )
  req = Net::HTTP::Get.new uri.request_uri

  http = Net::HTTP.new uri.host, uri.port
  http.use_ssl = true
  http.set_debug_output $stdout if $DEBUG

  res = http.start { |http|
    http.request req
  }
  case res
  when Net::HTTPSuccess
    body = res.body

    jsn = JSON.parse body

    status = jsn['Status'] || {}
    statusCode = status['StatusCode'] || 0
    if statusCode != 0
      raise "Error from service #{svcname}: #{status['StatusCode']} #{status['statusMessage']} #{status['ExceptionDetails']}"
    end

    jsn
  else
    raise "Error from #{uri}: #{res.code} #{res.message}"
  end
end

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

jsn = call_gc 'GetPocketQueryList', access_token

pqlist = jsn['PocketQueryList'] || []
pqlist.each { |pq|
  lastgen = Time.at(pq['DateLastGenerated'][6..-1].to_f / 1000)

  pqname = pq['Name']

  puts <<-EOM
========================================
#{pqname}: #{pq['PQCount']} caches, #{pq['FileSizeInBytes']} bytes
#{pq['GUID']}
available: #{pq['IsDownloadAvailable']}
generated: #{lastgen.strftime '%Y-%m-%d %H:%M:%S'}
========================================
  EOM

  puts "Downloading #{pqname}..."

  jsn2 = call_gc 'GetPocketQueryZippedFile', access_token, :pocketQueryGuid => pq['GUID']
  if jsn2['ZippedFile']
    zipdata = Base64.decode64 jsn2['ZippedFile']
    File.open("#{pqname}.zip", 'wb') { |file|
      file.write zipdata
    }
  end
}
