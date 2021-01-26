# GitLab

My own modified fork of GitLab.

## Features (other than upstream)
- systemd support
- night mode by default
- streamlined setup

## How to install

This documentation is customized to my needs. If you want to use this, you should at least read the [official documentation](https://docs.gitlab.com/ee/install/installation.html) before pressing any buttons.

**Currently all commands are set up to install v13.8! Everything is run as `root`, you need the `backports` repo on Debian.**

1. Install dependencies
    - `apt install sudo libimage-exiftool-perl graphicsmagick zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev libreadline-dev libncurses5-dev libffi-dev curl openssh-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev logrotate rsync python-docutils pkg-config cmake runit libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev libpcre2-dev build-essential`
2. Install the `git` version provided by `gitaly`:
    - `git clone https://gitlab.com/gitlab-org/gitaly.git -b 13-8-stable /tmp/gitaly`
    - `cd /tmp/gitaly`
    - `make git GIT_PREFIX=/usr/local`
3. Install Ruby
    - `mkdir /tmp/ruby && cd /tmp/ruby`
    - `curl --remote-name --progress-bar "https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.2.tar.gz"`
    - `tar xzf ruby-2.7.2.tar.gz`
    - `cd ruby-2.7.2`
    - `./configure --disable-install-rdoc`
    - `make && make install`
4. Install Go
    - `cd ~`
    - `curl --remote-name --progress-bar "https://dl.google.com/go/go1.15.7.linux-amd64.tar.gz"`
    - `tar -C /usr/local -xzf go1.15.7.linux-amd64.tar.gz`
    - `ln -svf /usr/local/go/bin/{go,godoc,gofmt} /usr/local/bin/`
    - `rm go1.15.7.linux-amd64.tar.gz`
5. Install NodeJS and yarn
    - `curl --location "https://deb.nodesource.com/setup_14.x" | sudo bash -`
    - `curl --silent --show-error "https://dl.yarnpkg.com/debian/pubkey.gpg" | sudo apt-key add -`
    - `echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list`
    - `apt-get update && apt-get install nodejs yarn`
6. Add `git` user
    - `adduser --disabled-login --gecos 'GitLab' git`
7. Install and configure PostgreSQL
    - `apt install -y postgresql postgresql-client libpq-dev postgresql-contrib`
    - `systemctl start postgresql`
    - `sudo -u postgres psql -d template1 -c "CREATE USER git CREATEDB;"`
    - `sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"`
    - `sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS btree_gist;"`
    - `sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"`
    - `sudo -u git -H psql -d gitlabhq_production`
        - `SELECT true AS enabled FROM pg_available_extensions WHERE name = 'pg_trgm' AND installed_version IS NOT NULL; SELECT true AS enabled FROM pg_available_extensions WHERE name = 'btree_gist' AND installed_version IS NOT NULL;`
8. Install and configure Redis
    - `apt-get install redis-server`
    - `cp /etc/redis/redis.conf /etc/redis/redis.conf.orig`
    - `sed 's/^port .*/port 0/' /etc/redis/redis.conf.orig | tee /etc/redis/redis.conf`
    - `echo 'unixsocket /var/run/redis/redis.sock' | tee -a /etc/redis/redis.conf`
    - `echo 'unixsocketperm 770' | tee -a /etc/redis/redis.conf`
    - `mkdir -p /var/run/redis`
    - `chown redis:redis /var/run/redis`
    - `chmod 755 /var/run/redis`
    - `echo 'd  /var/run/redis  0755  redis  redis  10d  -' | sudo tee -a /etc/tmpfiles.d/redis.conf`
    - `usermod -aG redis git`
    - `systemctl restart redis-server`
9. Install GitLab itself
    - `cd /home/git`
    - `sudo -u git -H git clone https://github.com/lfuelling/gitlab.git -b 13-8-stable gitlab`
    - `cd /home/git/gitlab`
    - `sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml`
    - Editor: `sudo -u git -H editor config/gitlab.yml`
    - `sudo -u git -H cp config/secrets.yml.example config/secrets.yml`
    - `sudo -u git -H chmod 0600 config/secrets.yml`
    - `chown -R git log/`
    - `chown -R git tmp/`
    - `chmod -R u+rwX,go-w log/`
    - `chmod -R u+rwX tmp/`
    - `chmod -R u+rwX tmp/pids/`
    - `chmod -R u+rwX tmp/sockets/`
    - `sudo -u git -H mkdir -p public/uploads/`
    - `chmod 0700 public/uploads`
    - `chmod -R u+rwX builds/`
    - `chmod -R u+rwX shared/artifacts/`
    - `chmod -R ug+rwX shared/pages/`
    - `sudo -u git -H cp config/puma.rb.example config/puma.rb`
    - Editor: `sudo -u git -H editor config/puma.rb`
    - `sudo -u git -H git config --global core.autocrlf input`
    - `sudo -u git -H git config --global gc.auto 0`
    - `sudo -u git -H git config --global repack.writeBitmaps true`
    - `sudo -u git -H git config --global receive.advertisePushOptions true`
    - `sudo -u git -H git config --global core.fsyncObjectFiles true`
    - `sudo -u git -H cp config/resque.yml.example config/resque.yml`
    - Editor: `sudo -u git -H editor config/resque.yml`
    - `sudo -u git cp config/database.yml.postgresql config/database.yml`
    - Editor: `sudo -u git -H editor config/database.yml`
        - If you use PostgreSQL via socket, it's enough to delete `host`, `username` and `password`
    - `sudo -u git -H chmod o-rwx config/database.yml`
    - `sudo -u git -H bundle install --deployment --without development test mysql aws kerberos`
10. Install and configure GitLab Shell
    - `sudo -u git -H bundle exec rake gitlab:shell:install RAILS_ENV=production`
    - Editor: `sudo -u git -H editor /home/git/gitlab-shell/config.yml`
11. Install and configure GitLab Workhorse
    - `sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production`
12. Install and configure Gitaly
    - `cd /home/git/gitlab`
    - `sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production`
    - `chmod 0700 /home/git/gitlab/tmp/sockets/private`
    - `chown git /home/git/gitlab/tmp/sockets/private`
    - Editor: `sudo -u git -H editor /home/git/gitaly/config.toml`
    - `cp lib/support/systemd/gitlab-gitaly.service /etc/systemd/system/gitlab-gitaly.service`
    - `systemctl daemon-reload && systemctl start gitlab-gitaly`
13. Initialize Database
    - `sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production`
14. Set up Logrotate
    - `sudo cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab`
15. Precompile stuff
    - `sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production`
    - `sudo -u git -H yarn install --production --pure-lockfile`
    - `sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production`
16. Set up systemd
    - `cp lib/support/systemd/gitlab-gitaly.service /etc/systemd/system/gitlab-gitaly.service`
    - `cp lib/support/systemd/gitlab-mailroom.service /etc/systemd/system/gitlab-mailroom.service`
    - `cp lib/support/systemd/gitlab-puma.service /etc/systemd/system/gitlab-puma.service`
    - `cp lib/support/systemd/gitlab-sidekiq.service /etc/systemd/system/gitlab-sidekiq.service`
    - `cp lib/support/systemd/gitlab-workhorse.service /etc/systemd/system/gitlab-workhorse.service`
    - `systemctl daemon-reload`
    - `systemctl enable gitlab-gitaly`
    - `systemctl enable gitlab-mailroom`
    - `systemctl enable gitlab-puma`
    - `systemctl enable gitlab-sidekiq`
    - `systemctl enable gitlab-workhorse`
    - `systemctl start gitlab-gitaly`
    - `systemctl start gitlab-mailroom`
    - `systemctl start gitlab-puma`
    - `systemctl start gitlab-sidekiq`
    - `systemctl start gitlab-workhorse`
17. Install and configure NGINX
    - `apt install nginx`
    - `cp lib/support/nginx/gitlab /etc/nginx/sites-available/gitlab`
    - `ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab`
    - Editor: `editor /etc/nginx/sites-available/gitlab`
    - `systemctl restart nginx`
18. Check application status
    - `sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production`
19. Get a Rails console and set the root password
    - `sudo -u git -H bundle exec rails console -e production`
        - `user = User.where(id: 1).first`
        - `user.password = 'secret_pass'`
        - `user.password_confirmation = 'secret_pass'`
        - `user.send_only_admin_changed_your_password_notification!`
        - `user.save!`

## Troubleshooting

### Restarting all the services
```
systemctl restart gitlab-gitaly && systemctl restart gitlab-mailroom && systemctl restart gitlab-puma && systemctl restart gitlab-sidekiq && systemctl restart gitlab-workhorse
```
