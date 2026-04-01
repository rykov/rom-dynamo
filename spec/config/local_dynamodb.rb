# frozen_string_literal: true

module LocalDynamoDB
  JAVA_DIR = File.expand_path('../java', __dir__)
  LIB_DIR = File.join(JAVA_DIR, 'target/lib')
  PORT = 8000

  class << self
    def installed?
      Dir.exist?(LIB_DIR) && !Dir.glob(File.join(LIB_DIR, 'DynamoDBLocal-*.jar')).empty?
    end

    def running?
      Net::HTTP.start('localhost', PORT, open_timeout: 1, read_timeout: 1) do |http|
        http.post('/', '{}', 'Content-Type' => 'application/x-amz-json-1.0',
                             'X-Amz-Target' => 'DynamoDB_20120810.ListTables')
      end
      true
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EPIPE, EOFError, Net::OpenTimeout, Net::ReadTimeout
      false
    end

    def start
      return if running?
      return unless installed?

      classpath = File.join(LIB_DIR, '*')
      @pid = spawn(
        'java', "-Djava.library.path=#{LIB_DIR}", '-cp', classpath,
        'software.amazon.dynamodb.services.local.main.ServerRunner',
        '-sharedDb', '-inMemory', '-port', PORT.to_s,
        chdir: File.join(JAVA_DIR, 'target'), out: File::NULL, err: File::NULL
      )
      Process.detach(@pid)

      wait_until_ready
    end

    def stop
      return unless @pid
      Process.kill('TERM', @pid)
      Process.wait(@pid, Process::WNOHANG)
      @pid = nil
    rescue Errno::ESRCH, Errno::ECHILD
      @pid = nil
    end

  private

    def wait_until_ready(timeout: 10)
      deadline = Time.now + timeout
      until running?
        raise "DynamoDB Local failed to start within #{timeout}s" if Time.now > deadline
        sleep 0.2
      end
    end
  end
end

require 'net/http'

# Start eagerly so DynamoDB is available before reset_cluster runs at load time
LocalDynamoDB.start

at_exit { LocalDynamoDB.stop }
