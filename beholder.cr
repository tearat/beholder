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
        parser.on("-t", "--time", "Shows elapsed time") { options[:time] = "true" }
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


all_arg  = options.has_key?(:all)  ? true : nil
file_arg = options.has_key?(:file) ? options[:file] : nil
get_arg  = options.has_key?(:get)  ? options[:get]  : nil
time_arg = options.has_key?(:time) ? options[:time]  : nil


# Overwrite list
if file_arg
    filename = file_arg
end


if all_arg || get_arg
    sites = [] of String
    if get_arg
        sites.push get_arg
    else
        begin
            sites = File.read_lines(filename)
        rescue error : File::NotFoundError
            puts "File #{filename} not found".colorize.red
        end
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
            start_time = Time.local
            response = HTTP::Client.get site
            elapsed_time = Time.local - start_time
            code = response.status_code
            if /[2,3].{2}/ =~ code.to_s
                report = "#{site.ljust(max_len)}=> #{code.to_s.colorize.green}"
                if time_arg
                    report += " [ #{elapsed_time} ]"
                end
                puts report
            else
                report = "#{site.ljust(max_len)}=> #{code.to_s.colorize.red}"
                if time_arg
                    report += " [ #{elapsed_time} ]"
                end
                puts report
            end
        rescue error : Socket::Addrinfo::Error
            puts "#{site.ljust(max_len)}=> #{"Host not found".colorize.red}"
        end
    end
end
