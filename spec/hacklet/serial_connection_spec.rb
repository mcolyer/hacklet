require 'spec_helper'

describe Hacklet::SerialConnection do
  subject { Hacklet::SerialConnection.new(Logger.new('/dev/null')) }

  describe 'initialization' do
    it 'creates a serial port with no flow control' do
      serial_port = mock('SerialPort')
      serial_port.should_receive(:flow_control=)

      SerialPort.should_receive(:new).and_return(serial_port)
      subject
    end
  end

  describe 'transmitting' do
    subject { Hacklet::SerialConnection.new(Logger.new('/dev/null')) }

    it 'is successful' do
      serial_port = mock('SerialPort')
      serial_port.should_receive(:flow_control=)
      serial_port.should_receive(:write).with([0x02, 0x40, 0x04, 0x00, 0x44].pack('c*'))

      SerialPort.should_receive(:new).and_return(serial_port)
      subject.transmit(Hacklet::BootRequest.new)
    end
  end

  describe 'receiving' do
    subject { Hacklet::SerialConnection.new(Logger.new('/dev/null')) }

    it 'is successful' do
      serial_port = mock('SerialPort')
      serial_port.should_receive(:flow_control=)
      serial_port.should_receive(:read).and_return("\x02")

      SerialPort.should_receive(:new).and_return(serial_port)
      subject.receive(1).should eq("\x02")
    end
  end
end
