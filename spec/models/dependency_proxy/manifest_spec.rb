# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::Manifest, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:file_name) }
    it { is_expected.to validate_presence_of(:digest) }
  end

  describe 'file is being stored' do
    subject { create(:dependency_proxy_manifest) }

    context 'when existing object has local store' do
      it_behaves_like 'mounted file in local store'
    end

    context 'when direct upload is enabled' do
      before do
        stub_dependency_proxy_object_storage(direct_upload: true)
      end

      it_behaves_like 'mounted file in object store'
    end
  end

  describe '.find_or_initialize_by_file_name' do
    subject { DependencyProxy::Manifest.find_or_initialize_by_file_name(file_name) }

    context 'no manifest exists' do
      let_it_be(:file_name) { 'foo' }

      it 'initializes a manifest' do
        expect(DependencyProxy::Manifest).to receive(:new).with(file_name: file_name)

        subject
      end
    end

    context 'manifest exists' do
      let_it_be(:dependency_proxy_manifest) { create(:dependency_proxy_manifest) }
      let_it_be(:file_name) { dependency_proxy_manifest.file_name }

      it { is_expected.to eq(dependency_proxy_manifest) }
    end
  end
end
