---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Metrics Dictionary Guide

This guide describes Metrics Dictionary and how it's implemented

## Metrics Definition and validation

We are using [JSON Schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json) to validate the metrics definition.

This process is meant to ensure consistent and valid metrics defined for Usage Ping. All metrics *must*:

- Comply with the definied [JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json).
- Have a unique `full_path` .
- Have an owner.

All metrics are stored in YAML files:

- [`config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/metrics)

Each metric is definied in a separate YAML file consisting of a number of fields:

| Field               | Required | Additional information                                         |
|---------------------|----------|----------------------------------------------------------------|
| `name`              | yes      |                                                                |
| `description`       | yes      |                                                                |
| `value_type`        | yes      |                                                                |
| `status`            | yes      |                                                                |
| `default_generation`| yes      | Default generation path of the metric. One full_path value. (1) |
| `full_path`         | yes      | Full path of the metric for one or multiple generations. Path of the metric in Usage Ping payload. (1) |
| `group`             | yes      | The [group](https://about.gitlab.com/handbook/product/categories/#devops-stages) that owns the metric. |
| `time_frame`        | yes      | `string`; may be set to a value like "7d"                             |
| `data_source`       | yes      | `string`: may be set to a value like `database` or `redis_hll`.       |
| `distribution`      | yes      | The [distribution](https://about.gitlab.com/handbook/marketing/strategic-marketing/tiers/#definitions) where the metric applies. |
| `tier`              | yes      | The [tier]( https://about.gitlab.com/handbook/marketing/strategic-marketing/tiers/) where the metric applies. |
| `product_category`  | no       | The [product category](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/categories.yml) for the metric. |
| `stage`             | no       | The [stage](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) for the metric. |
| `milestone`         | no       | The milestone when the metric is introduced. |
| `milestone_removed` | no       | The milestone when the metric is removed. |
| `introduced_by_url` | no       | The URL to the Merge Request that introduced the metric. |

1. The default generation path is the location of the metric in the Usage Ping payload.
   The `full_path` is the list locations for multiple Usage Ping generaations.

### Example metric definition

The linked [`uuid`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/license/uuid.yml)
YAML file includes an example metric definition, where the `uuid` metric is the GitLab
instance unique identifier.

```yaml
name: uuid
description: GitLab instance unique identifier
value_type: string
product_category: collection
stage: growth
status: data_available
default_generation: generation_1
full_path:
  generation_1: uuid
  generation_2: license.uuid
milestone: 9.1
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1521
group: group::product intelligence
time_frame: none
data_source: database
distribution: [ee, ce]
tier: ['free', 'starter', 'premium', 'ultimate', 'bronze', 'silver', 'gold']
```
