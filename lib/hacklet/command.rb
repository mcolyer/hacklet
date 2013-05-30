require 'slop'

module Hacklet
  class Command
    def self.run(dongle, arguments)
      Slop.parse(arguments, :help => true) do
        command 'on', :banner => 'Turn on the specifed socket' do
          on :n, :network=, 'The network id (ex. 0x1234)', :required => true
          on :s, :socket=, 'The socket id (ex. 0)', :required => true

          run do |opts, args|
            network_id = opts[:network][2..-1].to_i(16)
            socket_id = opts[:socket].to_i

            dongle.open_session do |session|
              session.lock_network
              session.select_network(network_id)
              session.switch(network_id, socket_id, true)
            end
          end
        end

        command 'off', :banner => 'Turn off the specifed socket' do
          on :n, :network=, 'The network id (ex. 0x1234)', :required => true
          on :s, :socket=, 'The socket id (ex. 0)', :required => true

          run do |opts, args|
            network_id = opts[:network][2..-1].to_i(16)
            socket_id = opts[:socket].to_i

            dongle.open_session do |session|
              session.lock_network
              session.select_network(network_id)
              session.switch(network_id, socket_id, false)
            end
          end
        end

        command 'read', :banner => 'Read all available samples from the specified socket' do
          on :n, :network=, 'The network id (ex. 0x1234)', :required => true
          on :s, :socket=, 'The socket id (ex. 0)', :required => true

          run do |opts, args|
            network_id = opts[:network][2..-1].to_i(16)
            socket_id = opts[:socket].to_i

            dongle.open_session do |session|
              session.lock_network
              session.select_network(network_id)
              session.request_samples(network_id, socket_id)
            end
          end
        end

        command 'commission', :banner => 'Add a new device to the network' do
          run do |opts, args|
            dongle.open_session do |session|
              session.commission
            end
          end
        end

        run do
          puts help
        end
      end
    end
  end
end
