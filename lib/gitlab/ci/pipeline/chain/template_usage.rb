# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class TemplateUsage < Chain::Base
          def perform!
            included_templates.each do |template|
              track_event(template)
            end
          end

          def break?
            false
          end

          private

          def track_event(template)
            Gitlab::UsageDataCounters::CiTemplateUniqueCounter
              .track_unique_project_event(project_id: pipeline.project_id, template: template)
          end

          def included_templates
            command.yaml_processor_result.included_templates
          end
        end
      end
    end
  end
end
