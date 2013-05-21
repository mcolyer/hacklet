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
    # [02][40][84][16][3962850049687596436A][0B2F000000584F80][0A1C][XX]
    #
    # 1 - Header
    # 2 - Mode
    # 3 - Command
    # 4 - Payload size - the number of bytes following this.
    # 5 - ?
    # 6 - Device Id
    # 7 - XOR checksum
  end

  class BootConfirm < Base
    # I really don't know what this is for.
    #
    # RX packet: [02][40][80][01][10][XX]
    # 1 - Header
    # 2 - mode
    # 3 - command
    # 4 - payload size - the number of bytes following this.
    # 5 - ?
    # 6 - XOR checksum
  end

  class Lock < Base
    # I really don't know what this is for.
    #
    # RX packet: [02][A0][F9][01][00][XX]
    # 1 - header
    # 2 - mode
    # 3 - command
    # 4 - payload size - the number of bytes following this.
    # 5 - ?
    # 6 - XOR checksum
  end

  class Ack < Base
    # I think this is an acknowledgement packet.
    #
    # RX packet: [02][40][24][01][00][XX]
    # 1 - header
    # 2 - command
    # 3 - payload size - the number of bytes following this.
    # 4 - ?
  end

  class Samples < Base
    # RX packet: [02][40][A4][10][A7B4][0001][0A00][55E09751][0100][0000][0000][XX]
    # 1 - header
    # 1 - mode
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
    # 12 - XOR checksum
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
    # 1 - mode
    # 2 - command (query)
    # 3 - payload byte size
    # 4 - XOR checksum
    def initialize
      @data = '02 40 04 00 44'
    end
  end

  class BootConfirm < Base
    # TX packet: 02[40][00][00][40]
    # 1 - header
    # 1 - mode
    # 2 - command (query)
    # 3 - payload byte size
    # 4 - checksum
    def initialize
      @data = '02 40 00 00 40'
    end
  end

  class Lock < Base
    # TX packet: [02]A23604FCFF0001[92]
    # 1 - header
    # 4 - checksum
    def initialize
      @data = '02 A2 36 04 FC FF 00 01 92'
    end
  end

  class Handshake < Base
    # TX packet: 02[40][03][04][A7B4]0500[51]
    # 1 - header
    # 1 - mode
    # 1 - command
    # 1 - payload length
    # 1 - network
    # 1 - ?
    # 1 - XOR checksum
    def initialize(network)
      @data = "02 40 03 04 #{network} 05 00 51"
    end
  end

  class Samples < Base
    # TX packet: 02[40][2406][A7B4][0001][0A][00][7B]
    # 1 - header
    # 1 - mode
    # 2 - command (query)
    # 3 - network id
    # 4 - channel id
    # 5 - ?
    # 6 - payload byte size
    # 7 - checksum
    def initialize(network, channel_id)
      # FIXME: The checksum is somehow influenced by the channel id and
      # possibly the network but I can't figure out how.
      @data = "02 40 24 06 #{network} 00 01 0A 00 7A"
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
    Responses::BootConfirm.new(receive(6))
  end

  # Public: Locks the network.
  #
  # Not sure from what but that's what the logs say.
  #
  # Returns the BootConfirmResponse
  def lock_network
    transmit(Requests::Lock.new)
    Responses::Lock.new(receive(6))
  end

  # Public: Required initialization step.
  #
  # Don't really have a good guess of what this does, maybe selects the network?
  def handshake(network)
    transmit(Requests::Handshake.new(network))
    Responses::Ack.new(receive(6))
  end

  # Public: Request stored samples.
  #
  # Returns the Responses::Samples
  def request_samples(network, channel_id)
    transmit(Requests::Samples.new(network, channel_id))
    Responses::Ack.new(receive(6))
    buffer = receive(4)
    remaining_bytes = buffer.split(' ')[3].to_i(16)+1
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
    @logger.debug("RX: #{unpack(response).join(' ')}")

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
dongle.handshake('A7 B4')
logger.info("Requesting samples")
dongle.request_samples('A7 B4', '00 01')
logger.info("Samples recieved")
