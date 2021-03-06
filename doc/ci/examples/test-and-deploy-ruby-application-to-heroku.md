---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: tutorial
---

# Test and deploy a Ruby application with GitLab CI/CD

This example will guide you through how to run tests in your Ruby on Rails application and deploy it automatically as a Heroku application.

You can also view or fork the complete [example source](https://gitlab.com/ayufan/ruby-getting-started) and view the logs of its past [CI jobs](https://gitlab.com/ayufan/ruby-getting-started/-/jobs?scope=finished).

## Configure the project

This is what the `.gitlab-ci.yml` file looks like for this project:

```yaml
test:
  stage: test
  script:
    - apt-get update -qy
    - apt-get install -y nodejs
    - bundle install --path /cache
    - bundle exec rake db:create RAILS_ENV=test
    - bundle exec rake test

staging:
  stage: deploy
  script:
    - gem install dpl --pre
    - dpl heroku api --app=gitlab-ci-ruby-test-staging --api-key=$HEROKU_STAGING_API_KEY
  only:
    - master

production:
  stage: deploy
  script:
    - gem install dpl --pre
    - dpl heroku api --app=gitlab-ci-ruby-test-prod --api-key=$HEROKU_PRODUCTION_API_KEY
  only:
    - tags
```

This project has three jobs:

- `test` - used to test Rails application.
- `staging` - used to automatically deploy staging environment every push to `master` branch.
- `production` - used to automatically deploy production environment for every created tag.

## Store API keys

You'll need to create two variables in your project's **Settings > CI/CD > Environment variables** and do not check **Protect variable** and **Mask variable**:

- `HEROKU_STAGING_API_KEY` - Heroku API key used to deploy staging app.
- `HEROKU_PRODUCTION_API_KEY` - Heroku API key used to deploy production app.

Find your Heroku API key in [Manage Account](https://dashboard.heroku.com/account).

## Create Heroku application

For each of your environments, you'll need to create a new Heroku application.
You can do this through the [Heroku Dashboard](https://dashboard.heroku.com/).

## Create a runner

First install [Docker Engine](https://docs.docker.com/installation/).

To build this project you also need to have [GitLab Runner](https://docs.gitlab.com/runner/).
You can use public runners available on `gitlab.com` or register your own. Start by
creating a template configuration file to pass complex configuration:

```shell
cat > /tmp/test-config.template.toml << EOF
[[runners]]
[runners.docker]
[[runners.docker.services]]
name = "postgres:latest"
EOF
```

Finally, register the runner, passing the newly-created template configuration file:

```shell
gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --description "ruby:2.6" \
  --executor "docker" \
  --template-config /tmp/test-config.template.toml \
  --docker-image ruby:2.6
```

With the command above, you create a runner that uses the [`ruby:2.6`](https://hub.docker.com/_/ruby) image and uses a [PostgreSQL](https://hub.docker.com/_/postgres) database.

To access the PostgreSQL database, connect to `host: postgres` as user `postgres` with no password.
