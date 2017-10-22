require 'rails_helper'
require 'slack_client'

describe WarningJob, type: :job do
  let(:job) { described_class.new }
  let(:client) { double('SlackClient') }
  let(:manage_client) { double('SlackClient') }
  let(:channel_name) { 'channel' }
  let(:warned_at) { nil }
  let!(:channel) do
    Channel.create(
      cid: 'cid',
      name: channel_name,
      master: '@user',
      active: 'true',
      warned_at: warned_at,
      created_at: 10.days.ago
    )
  end

  describe '#perform' do
    before do
      allow(SlackClient).to receive(:build_bot_client).and_return(client)
      allow(SlackClient).to receive(:build_manage_client).and_return(manage_client)
      allow(manage_client).to receive(:chat_postMessage)
    end

    context 'with inactive candidate' do
      it 'works properly' do
        expect(client).to receive(:chat_postMessage)
        job.perform
        expect(channel.reload.warned_at).not_to be_nil
      end

      context 'with already warned' do
        let(:warned_at) { 2.days.ago }

        it 'skips' do
          expect(client).not_to receive(:chat_postMessage)
          job.perform
          expect(channel.reload.warned_at).not_to be_nil
        end
      end
    end

    context 'with not inactive candidate' do
      let(:channel_name) { '_channel' }
      let(:warned_at) { 2.days.ago }

      it 'reset warned_at' do
        expect(client).not_to receive(:chat_postMessage)
        job.perform
        expect(channel.reload.warned_at).to be_nil
      end
    end

    context 'with error' do
      it 'send error information to manage slack' do
        expect(client).to receive(:chat_postMessage).and_raise(StandardError)
        expect {
          job.perform
        }.not_to raise_error
      end
    end
  end
end