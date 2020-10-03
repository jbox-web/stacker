# config valid for current version and patch releases of Capistrano
lock '~> 3.14.0'

set :application, 'saltstack-config'
set :repo_url,    'repo url'
set :deploy_to,   '/data/stacker'

append :linked_dirs, 'log'

namespace :stacker do
  desc 'Restart Stacker'
  task :restart do
    on roles(:all) do |host|
      execute :sudo, 'systemctl', 'restart', 'stacker.service'
    end
  end
end

namespace :deploy do
  after 'deploy:finished', 'stacker:restart'
end
