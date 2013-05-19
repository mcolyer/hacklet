require 'serialport'
require 'logger'

module Responses
  class Base
    def initialize(data)
      @data = data
    end
  end

  class Boot < Base
    # It's unclear what useful information is in here.
    #
    # Example Response:
    # [40][84][16][3962850049687596436A][0B2F000000584F80][0A1C]
    #
    # 1 - Header
    # 2 - Command
    # 3 - Payload size - the number of bytes following this.
    # 4 - ?
    # 5 - Device Id
    # 6 - ?
  end

  class BootConfirm < Base
    # I really don't know what this is for.
    #
    # RX packet: [40][80][01][10]
    # 1 - header
    # 2 - command
    # 3 - payload size - the number of bytes following this.
    # 4 - ?
  end

  class Lock < Base
    # I really don't know what this is for.
    #
    # RX packet: [A0][F9][01][00]
    # 1 - header
    # 2 - command
    # 3 - payload size - the number of bytes following this.
    # 4 - ?
  end

  class Ack < Base
    # I think this is an acknowledgement packet.
    #
    # RX packet: [40][24][01][00]
    # 1 - header
    # 2 - command
    # 3 - payload size - the number of bytes following this.
    # 4 - ?
  end

  class Samples < Base
    # RX packet: [40][A4][10][A7B4][0001][0A00][55E09751][01][000000][0000] - 19 bytes
    # 1 - header
    # 2 - command
    # 3 - payload size - the number of bytes following this.
    # 3 - network id "NwkAdr"
    # 4 - channel id
    # 5 - ?
    # 7 - time in seconds (stored as little-endian) standard unix epoch
    # 8 - number of readings in packet
    # 9 - stored number of readings (little endian)
    # 10 - reading 1 watts * 13 (I don't get the use of 13 here) (little endian) - 2 bytes
    # 11 - (additional readings are appended upto 20)
  end
end

module Requests
  class Base
    def to_s
      @data
    end
  end

  class Boot < Base
    # TX packet: 02[40][04][00][44]
    # 1 - header
    # 2 - command (query)
    # 3 - payload byte size
    # 4 - checksum
    def initialize
      @data = '02 40 04 00 44'
    end
  end

  class BootConfirm < Base
    # TX packet: 02[40][00][00][40]
    # 1 - header
    # 2 - command (query)
    # 3 - payload byte size
    # 4 - checksum
    def initialize
      @data = '02 40 00 00 40'
    end
  end

  class Lock < Base
    # TX packet: 02A23604FCFF000192
    def initialize
      @data = '02 A2 36 04 FC FF 00 01 92'
    end
  end

  class Samples < Base
    # TX packet: 02[40][2406][A7B4][0001][0A][00][7B]
    # 1 - header
    # 2 - command (query)
    # 3 - network id
    # 4 - channel id
    # 5 - ?
    # 6 - payload byte size
    # 7 - unknown checksum algorithm
    def initialize(network, channel_id)
      # FIXME: The checksum is somehow influenced by the channel id and
      # possibly the network but I can't figure out how.
      @data = "02 40 24 06 #{network} 00 01 0A 00 7B"
    end
  end
end

class Dongle
  def initialize(logger=Logger.new(STDOUT), port='/dev/ttyUSB0')
    @serial = SerialPort.new('/dev/ttyUSB0', 115200, 8, 1, SerialPort::NONE)
    @logger = logger
  end

  # Public: Initializes the dongle for communication
  #
  # TX packet: 400400
  #
  # Returns the BootResponse
  def boot
    transmit(Requests::Boot.new)
    Responses::Boot.new(receive(27))
  end

  # Public: Confirms that booting was successful?
  #
  # Not sure about this.
  #
  # Returns the BootConfirmResponse
  def boot_confirm
    transmit(Requests::BootConfirm.new)
    Responses::BootConfirm.new(receive(4))
  end

  # Public: Locks the network.
  #
  # Not sure from what but that's what the logs say.
  #
  # Returns the BootConfirmResponse
  def lock_network
    transmit(Requests::Lock.new)
    Responses::Lock.new(receive(4))
  end

  # Public: Request stored samples.
  #
  # Returns the Responses::Samples
  def request_samples(network, channel_id)
    transmit(Requests::Samples.new(network, channel_id))
    Responses::Ack.new(receive(4))
    buffer = receive(3)
    remaining_bytes = buffer[2].unpack('c')
    buffer += receive(remaining_bytes)
    Responses::Samples.new(buffer)
  end

private
  def transmit(command)
    @logger.debug("TX: #{command}")
    @serial.write(pack(command.to_s)) if @serial
  end

  def receive(bytes)
    if @serial
      response = @serial.read(bytes)
    else
      response = "\x0\x0\x0\x0"
    end
    @logger.debug("RX: #{unpack(response)}")

    unpack(response).join(' ')
  end

  def pack(str)
    bytes = str.split(' ')
    bytes.pack('H2'*bytes.size)
  end

  def unpack(message)
    message.unpack('H2'*message.size)
  end
end

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
dongle = Dongle.new(logger)

logger.info("Booting")
dongle.boot
dongle.boot_confirm
logger.info("Booting complete")
logger.info("Locking network")
dongle.lock_network
logger.info("Locking complete")
logger.info("Requesting samples")
dongle.request_samples('A7 B4', '00 01')
logger.info("Samples recieved")
