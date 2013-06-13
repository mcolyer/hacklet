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
      serial_port.should_receive(:write).with("\x02\xA26\x04\xFC\xFF\x00\x01\x92")

      SerialPort.should_receive(:new).and_return(serial_port)
      subject.transmit(Hacklet::LockRequest.new)
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
