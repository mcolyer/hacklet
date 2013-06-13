require 'spec_helper'

describe Hacklet::Command do
  subject do
    Hacklet::Command
  end

  let(:dongle) do
    serial_connection = mock('serial_port')
    Hacklet::Dongle.new(serial_connection, Logger.new("/dev/null"))
  end

  it 'can turn on a socket' do
    dongle.should_receive(:lock_network)
    dongle.should_receive(:select_network).with(16)
    dongle.should_receive(:switch).with(16, 1, true)

    subject.run(dongle, ['on', '-n', '0x0010', '-s', '1'])
  end

  it 'can turn off a socket' do
    dongle.should_receive(:lock_network)
    dongle.should_receive(:select_network).with(16)
    dongle.should_receive(:switch).with(16, 0, false)

    subject.run(dongle, ['off', '-n', '0x0010', '-s', '0'])
  end

  it 'can read a socket' do
    dongle.should_receive(:lock_network)
    dongle.should_receive(:select_network).with(16)
    dongle.should_receive(:request_samples).with(16, 1)

    subject.run(dongle, ['read', '-n', '0x0010', '-s', '1'])
  end

  it 'can commission a device' do
    dongle.should_receive(:commission)

    subject.run(dongle, ['commission'])
  end
end
