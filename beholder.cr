require "option_parser"
require "http/client"
require "colorize"

options = {} of Symbol => String
filename = File.join(File.dirname(__FILE__), "/list.txt")

begin
    OptionParser.parse do |parser|
        parser.banner = "Usage: sauron.rb [options]"
        parser.on("-g URL", "--get=URL", "Scan selected URL") { |url| options[:get] = url }
        parser.on("-a", "--all", "Scan all sites in the list") { options[:all] = "true" }
        parser.on("-f FILE", "--file=FILE", "Specify file to use") { |file| options[:file] = file }
        parser.on("-h", "--help", "Show this help") { puts parser }
    end
rescue error : OptionParser::InvalidOption
    puts "Error: #{error}".colorize.light_yellow
rescue error : OptionParser::MissingOption
    puts "Error: #{error}".colorize.light_yellow
end


if options.empty?
    puts "Command not selected. Try --help".colorize.light_yellow
end


if options.has_key?(:file)
    filename = options[:file]
end


if options.has_key?(:get)
    site = options[:get]
    begin
        response = HTTP::Client.get site
        code = response.status_code
        if /[2,3].{2}/ =~ code.to_s
            puts "#{site} => #{code.to_s.colorize.green}"
        else
            puts "#{site} => #{code.to_s.colorize.red}"
        end
    rescue error : Socket::Addrinfo::Error
        puts "#{site} => #{"Host not found".colorize.red}"
    end
end


if options.has_key?(:all)
    sites = [] of String
    begin
        sites = File.read_lines(filename)
    rescue error : File::NotFoundError
        puts "File #{filename} not found".colorize.red
    end

    max_len = 0
    sites.each do |site|
        if site.size > max_len
            max_len = site.size
        end
    end
    max_len += 1

    sites.each do |site|
        begin
            response = HTTP::Client.get site
            code = response.status_code
            if /[2,3].{2}/ =~ code.to_s
                puts "#{site.ljust(max_len)}=> #{code.to_s.colorize.green}"
            else
                puts "#{site.ljust(max_len)}=> #{code.to_s.colorize.red}"
            end
        rescue error : Socket::Addrinfo::Error
            puts "#{site.ljust(max_len)}=> #{"Host not found".colorize.red}"
        end
    end
end
