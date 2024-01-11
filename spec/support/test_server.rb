require 'childprocess'
require 'net/http'
require 'logger'

class TestServer
  class << self
    attr_reader :server

    def start
      @server ||= new
    end

    def stop
      @server.stop
    end
  end

  attr_reader :process, :read_io, :server_url, :logger

  SERVER_URL = 'http://localhost:4567'.freeze

  def initialize
    @logger = Logger.new($stdout)
    start
    logging_thread
    wait_until_started
  end

  def stop
    @process.stop
    @read_io.close
    @logging_thread.kill
  end

  private

  def start
    @process = ChildProcess.build('ruby', File.join(__dir__, 'test_app.rb'))
    @read_io, write_io = IO.pipe
    @process.io.stdout = write_io
    @process.io.stderr = write_io
    @process.start
    write_io.close
  end

  def logging_thread
    @logging_thread ||= Thread.new do
      begin
        loop { print @read_io.readpartial(8192) }
      rescue EOFError
        logger.warn 'Server process has terminated'
      end
    end
  end

  def server_running?
    response = Net::HTTP.get_response(URI(SERVER_URL))
    response.is_a?(Net::HTTPSuccess)
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
    logger.warn 'Server not running'
    false
  end

  def wait_until_started(max_attempts = 20)
    max_attempts.times do
      return if server_running?

      sleep 0.5
    end
    raise 'Server failed to start'
  end
end
