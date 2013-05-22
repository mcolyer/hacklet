require 'spec_helper'

describe 'Message' do
  describe 'responses' do
    let(:bad_checksum) { "\x02\x40\x80\x01\x10\x01" }

    describe Hacklet::BootConfirmResponse do
      it 'detects an invalid checksum' do
        expect { Hacklet::BootConfirmResponse.read(bad_checksum) }.to raise_error(BinData::ValidityError)
      end
    end
  end

  describe 'requests' do
    describe Hacklet::BootRequest do
      it 'has a proper checksum' do
        subject.checksum.should eq(0x44)
      end
    end
  end
end
