# config valid for current version and patch releases of Capistrano
lock '~> 3.15.0'

set :application, 'saltstack-config'
set :repo_url,    'repo url'
set :deploy_to,   '/data/stacker'

append :linked_dirs, 'log'

namespace :stacker do
  desc 'Restart Stacker'
  task :restart do
    on roles(:stacker) do
      execute :sudo, 'systemctl', 'restart', 'stacker.service'
    end
  end
end

namespace :salt do
  desc 'Refresh Salt Pillar'
  task :refresh_pillar do
    on roles(:salt) do
      execute :salt, '"*"', '--timeout', '5', '--log-level', 'quiet', 'saltutil.refresh_pillar'
    end
  end

  desc 'Refresh Salt Mine'
  task :mine_update do
    on roles(:salt) do
      execute :salt, '"*"', '--timeout', '5', '--log-level', 'quiet', 'mine.update'
    end
  end
end

namespace :deploy do
  after 'deploy:finished', 'stacker:restart'
  after 'deploy:finished', 'salt:refresh_pillar'
  after 'deploy:finished', 'salt:mine_update'
end
