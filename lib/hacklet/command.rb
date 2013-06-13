require 'slop'
require 'logger'

module Hacklet
  class Command
    def self.run(dongle, arguments)
      Slop.parse(arguments, :help => true) do
        command 'on', :banner => 'Turn on the specifed socket' do
          on :n, :network=, 'The network id (ex. 0x1234)', :required => true
          on :s, :socket=, 'The socket id (ex. 0)', :required => true
          on :d, :debug, 'Enables debug logging' do
            dongle.logger.level = Logger::DEBUG
          end

          run do |opts, args|
            network_id = opts[:network][2..-1].to_i(16)
            socket_id = opts[:socket].to_i

            dongle.lock_network
            dongle.select_network(network_id)
            dongle.switch(network_id, socket_id, true)
          end
        end

        command 'off', :banner => 'Turn off the specifed socket' do
          on :n, :network=, 'The network id (ex. 0x1234)', :required => true
          on :s, :socket=, 'The socket id (ex. 0)', :required => true
          on :d, :debug, 'Enables debug logging' do
            dongle.logger.level = Logger::DEBUG
          end

          run do |opts, args|
            network_id = opts[:network][2..-1].to_i(16)
            socket_id = opts[:socket].to_i

            dongle.lock_network
            dongle.select_network(network_id)
            dongle.switch(network_id, socket_id, false)
          end
        end

        command 'read', :banner => 'Read all available samples from the specified socket' do
          on :n, :network=, 'The network id (ex. 0x1234)', :required => true
          on :s, :socket=, 'The socket id (ex. 0)', :required => true
          on :d, :debug, 'Enables debug logging' do
            dongle.logger.level = Logger::DEBUG
          end

          run do |opts, args|
            network_id = opts[:network][2..-1].to_i(16)
            socket_id = opts[:socket].to_i

            dongle.lock_network
            dongle.select_network(network_id)
            dongle.request_samples(network_id, socket_id)
          end
        end

        command 'commission', :banner => 'Add a new device to the network' do
          on :d, :debug, 'Enables debug logging' do
            dongle.logger.level = Logger::DEBUG
          end

          run do |opts, args|
            dongle.commission
          end
        end

        run do
          puts help
        end
      end
    end
  end
end
