require "bundler/capistrano"
require "capistrano-rbenv"
require "capistrano-unicorn"

load "deploy/assets"

set :rbenv_ruby_version, "1.9.3"

server = ENV['CAP_SERVER']

#default_run_options[:pty] = true


set :repository,  "git@github.com:crowdint/blog.crowdint.com.git"
set :git_shallow_clone, 1

set :application, "blog.crowdint.com"
set :user, "blog-crowdint-com"
set :deploy_to, "/home/blog-crowdint-com/www"
set :use_sudo, false
set :bundle_flags, "--deployment --quiet --binstubs"
set :rails_env, "production"
set :normalize_asset_timestamps, false
set :rbenv_path, "/usr/local/rbenv"
#set :rbenv_path, "$RBENV_ROOT"

# Servers
role :web, server
role :app, server
role :db,  server, :primary => true

set :default_environment, {
  'PATH' => "$RBENV_ROOT/shims:$RBENV_ROOT/bin:$PATH"
}

namespace :deploy do
  task :database_config do
    run "ln -s #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end

  namespace :assets do
    task :precompile, :roles => lambda { assets_role }, :except => { :no_release => true } do
      run <<-CMD.compact
      cd -- #{latest_release} &&
      #{rake} RAILS_ENV=#{rails_env.to_s.shellescape} #{asset_env} assets:precompile
      CMD
    end
  end
end

before "deploy:assets:precompile", "deploy:database_config"
after 'deploy:restart', 'unicorn:reload' # app IS NOT preloaded
after 'deploy:restart', 'unicorn:restart'  # app preloaded
