#!/usr/bin/env ruby
# encoding: utf-8

require "amqp"

AMQP.start(:host => "localhost") do |connection|
  channel  = AMQP::Channel.new(connection)
  exchange = channel.direct("direct_logs")
  queue    = channel.queue("", :exclusive => true)

  if ARGV.empty?
    abort "Usage: #{$0} [info] [warning] [error]"
  end

  ARGV.each do |severity|
    queue.bind(exchange, :routing_key => severity)
  end

  Signal.trap("INT") do
    connection.close do
      EM.stop { exit }
    end
  end

  puts " [*] Waiting for logs. To exit press CTRL+C"

  queue.subscribe do |header, body|
    puts " [x] #{header.routing_key}:#{body}"
  end
end
