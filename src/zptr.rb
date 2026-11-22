#!/usr/bin/env ruby

require "shellwords"

STORE = File.expand_path(ENV["ZPTR_FILE"] || "~/.zptr")

def read_ptr
    File.read(STORE).chomp if File.exist?(STORE)
end

case ARGV.first
when "set"
    File.write(STORE, Dir.pwd)
when "get"
    dir = read_ptr or abort "zptr: no pointer set (run `zptr set` first)"
    abort "zptr: gone: #{dir}" unless Dir.exist?(dir)
    puts "cd -- #{Shellwords.escape(dir)}"
when "show"
    puts(read_ptr || "(unset)")
when nil, "-h", "--help"
    puts "usage: zptr {set|get|show}"
else
    abort "zptr: unknown command #{ARGV.first.inspect}"
end
