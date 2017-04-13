require 'spec_helper'

describe Gitlab::Database::RenameReservedPathsMigration do
  let(:subject) do
    ActiveRecord::Migration.new.extend(
      Gitlab::Database::RenameReservedPathsMigration
    )
  end

  before do
    allow(subject).to receive(:say)
  end

  describe '#rename_wildcard_paths' do
    it 'should rename namespaces' do
      expect(subject).to receive(:rename_namespaces).
                           with(['first-path', 'second-path'], type: :wildcard)

      subject.rename_wildcard_paths(['first-path', 'second-path'])
    end

    it 'should rename projects'
  end

  describe '#rename_root_paths' do
    it 'should rename namespaces' do
      expect(subject).to receive(:rename_namespaces).
                           with(['the-path'], type: :top_level)

      subject.rename_root_paths('the-path')
    end
  end

  describe "#remove_last_ocurrence" do
    it "removes only the last occurance of a string" do
      input = "this/is/a-word-to-replace/namespace/with/a-word-to-replace"

      expect(subject.remove_last_occurrence(input, "a-word-to-replace"))
        .to eq("this/is/a-word-to-replace/namespace/with/")
    end
  end

  describe '#rename_path_for_routable' do
    context 'for namespaces' do
      let(:namespace) { create(:namespace, path: 'the-path') }
      it "renames namespaces called the-path" do
        subject.rename_path_for_routable(namespace)

        expect(namespace.reload.path).to eq("the-path0")
      end

      it "renames the route to the namespace" do
        subject.rename_path_for_routable(namespace)

        expect(Namespace.find(namespace.id).full_path).to eq("the-path0")
      end

      it "renames the route for projects of the namespace" do
        project = create(:project, path: "project-path", namespace: namespace)

        subject.rename_path_for_routable(namespace)

        expect(project.route.reload.path).to eq("the-path0/project-path")
      end

      it 'returns the old & the new path' do
        old_path, new_path = subject.rename_path_for_routable(namespace)

        expect(old_path).to eq('the-path')
        expect(new_path).to eq('the-path0')
      end

      context "the-path namespace -> subgroup -> the-path0 project" do
        it "updates the route of the project correctly" do
          subgroup = create(:group, path: "subgroup", parent: namespace)
          project = create(:project, path: "the-path0", namespace: subgroup)

          subject.rename_path_for_routable(namespace)

          expect(project.route.reload.path).to eq("the-path0/subgroup/the-path0")
        end
      end
    end

    context 'for projects' do
      let(:parent) { create(:namespace, path: 'the-parent') }
      let(:project) { create(:empty_project, path: 'the-path', namespace: parent) }

      it 'renames the project called `the-path`' do
        subject.rename_path_for_routable(project)

        expect(project.reload.path).to eq('the-path0')
      end

      it 'renames the route for the project' do
        subject.rename_path_for_routable(project)

        expect(project.reload.route.path).to eq('the-parent/the-path0')
      end

      it 'returns the old & new path' do
        old_path, new_path = subject.rename_path_for_routable(project)

        expect(old_path).to eq('the-parent/the-path')
        expect(new_path).to eq('the-parent/the-path0')
      end
    end
  end
end
