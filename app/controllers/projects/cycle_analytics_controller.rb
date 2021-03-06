# frozen_string_literal: true

class Projects::CycleAnalyticsController < Projects::ApplicationController
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include CycleAnalyticsParams
  include Analytics::UniqueVisitsHelper
  include GracefulTimeoutHandling

  before_action :authorize_read_cycle_analytics!

  track_unique_visits :show, target_id: 'p_analytics_valuestream'

  feature_category :planning_analytics

  def show
    @cycle_analytics = ::CycleAnalytics::ProjectLevel.new(@project, options: options(cycle_analytics_project_params))

    respond_to do |format|
      format.html do
        Gitlab::UsageDataCounters::CycleAnalyticsCounter.count(:views)

        render :show
      end
      format.json do
        render json: cycle_analytics_json
      end
    end
  end

  private

  def cycle_analytics_json
    {
      summary: @cycle_analytics.summary,
      stats: @cycle_analytics.stats,
      permissions: @cycle_analytics.permissions(user: current_user)
    }
  end
end
