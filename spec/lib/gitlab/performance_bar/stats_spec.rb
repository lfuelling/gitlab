# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PerformanceBar::Stats do
  describe '#process' do
    let(:request) { fixture_file('lib/gitlab/performance_bar/peek_data.json') }
    let(:redis) { double(Gitlab::Redis::SharedState) }
    let(:logger) { double(Gitlab::PerformanceBar::Logger) }
    let(:request_id) { 'foo' }
    let(:stats) { described_class.new(redis) }

    describe '#process' do
      subject(:process) { stats.process(request_id) }

      before do
        allow(stats).to receive(:logger).and_return(logger)
      end

      it 'logs each SQL query including its duration' do
        allow(redis).to receive(:get).and_return(request)

        expect(logger).to receive(:info)
          .with({ duration_ms: 1.096, filename: 'lib/gitlab/pagination/offset_pagination.rb',
                  filenum: 53, method: 'add_pagination_headers', request_id: 'foo', type: :sql })
        expect(logger).to receive(:info)
          .with({ duration_ms: 0.817, filename: 'lib/api/helpers.rb',
                  filenum: 112, method: 'find_project', request_id: 'foo', type: :sql }).twice

        subject
      end

      it 'logs an error when the request could not be processed' do
        allow(redis).to receive(:get).and_return(nil)

        expect(logger).to receive(:error).with(message: anything)

        subject
      end
    end
  end
end
