#  frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImportWorker do
  describe '#perform' do
    before do
      stub_const("#{described_class}::DEFAULT_BATCH_SIZE", 1)
    end

    context 'when no bulk import is found' do
      it 'does nothing' do
        expect(described_class).not_to receive(:perform_in)

        subject.perform(non_existing_record_id)
      end
    end

    context 'when bulk import is finished' do
      it 'does nothing' do
        bulk_import = create(:bulk_import, :finished)

        expect(described_class).not_to receive(:perform_in)

        subject.perform(bulk_import.id)
      end
    end

    context 'when all entities are processed' do
      it 'marks bulk import as finished' do
        bulk_import = create(:bulk_import, :started)
        create(:bulk_import_entity, :finished, bulk_import: bulk_import)
        create(:bulk_import_entity, :failed, bulk_import: bulk_import)

        subject.perform(bulk_import.id)

        expect(bulk_import.reload.finished?).to eq(true)
      end
    end

    context 'when maximum allowed number of import entities in progress' do
      it 'reenqueues itself' do
        bulk_import = create(:bulk_import, :started)
        (described_class::DEFAULT_BATCH_SIZE + 1).times { |_| create(:bulk_import_entity, :started, bulk_import: bulk_import) }

        expect(described_class).to receive(:perform_in).with(described_class::PERFORM_DELAY, bulk_import.id)

        subject.perform(bulk_import.id)
      end
    end

    context 'when bulk import is created' do
      it 'marks bulk import as started' do
        bulk_import = create(:bulk_import, :created)
        create(:bulk_import_entity, :created, bulk_import: bulk_import)

        subject.perform(bulk_import.id)

        expect(bulk_import.reload.started?).to eq(true)
      end

      context 'when there are created entities to process' do
        it 'marks a batch of entities as started, enqueues BulkImports::EntityWorker and reenqueues' do
          bulk_import = create(:bulk_import, :created)
          (described_class::DEFAULT_BATCH_SIZE + 1).times { |_| create(:bulk_import_entity, :created, bulk_import: bulk_import) }

          expect(described_class).to receive(:perform_in).with(described_class::PERFORM_DELAY, bulk_import.id)
          expect(BulkImports::EntityWorker).to receive(:perform_async)

          subject.perform(bulk_import.id)

          expect(bulk_import.entities.map(&:status_name)).to contain_exactly(:created, :started)
        end
      end
    end
  end
end
