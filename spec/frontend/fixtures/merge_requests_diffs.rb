# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequests::DiffsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'merge-requests-project') }
  let(:user) { project.owner }
  let(:merge_request) { create(:merge_request, :with_diffs, source_project: project, target_project: project, description: '- [ ] Task List Item') }
  let(:path) { "files/ruby/popen.rb" }
  let(:position) do
    build(:text_diff_position, :added,
      file: path,
      new_line: 14,
      diff_refs: merge_request.diff_refs
    )
  end

  render_views

  before(:all) do
    clean_frontend_fixtures('merge_request_diffs/')
  end

  before do
    sign_in(user)
  end

  after do
    remove_repository(project)
  end

  it 'merge_request_diffs/with_commit.json' do
    # Create a user that matches the project.commit author
    # This is so that the "author" information will be populated
    create(:user, email: project.commit.author_email, name: project.commit.author_name)

    render_merge_request(merge_request, commit_id: project.commit.sha)
  end

  private

  def render_merge_request(merge_request, view: 'inline', **extra_params)
    get :show, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param,
      view: view,
      **extra_params
    }, format: :json

    expect(response).to be_successful
  end
end
