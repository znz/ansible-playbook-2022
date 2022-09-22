# frozen-string-literal: true

all_tasks = []

namespace :misc do
  desc 'Ping all hosts'
  task :ping do
    sh 'ansible all -i hosts -m ping --one-line'
  end

  desc 'Show uptime'
  task :uptime do
    sh 'ansible all -i hosts -a uptime --one-line'
  end
end

namespace :ansible do
  env = { 'UPDATE_SSH_KEYS' => '1' }

  # example:
  #  rake 'ansible:runner[ns9]'
  desc 'Add ansible-runner'
  task :runner, [:host] do |_t, args|
    sh env, "ansible-playbook -i #{args.to_a.join(',')}, playbook/ansible-user.yml"
  end

  # example:
  #  rake 'ansible:runner_with_pass[ns8,ns6]'
  desc 'Add ansible-runner with become password'
  task :runner_with_pass, [:host] do |_t, args|
    sh env, "ansible-playbook -i #{args.to_a.join(',')}, playbook/ansible-user.yml -b -K"
  end

  # rake ansible:user UPDATE_SSH_KEYS=1
  task :user do
    sh 'ansible-playbook -i hosts playbook/ansible-user.yml'
  end
  all_tasks.push 'ansible:user'
end

namespace :apt do
  desc 'Apt update'
  task :update do
    sh 'ansible-playbook -i hosts playbook/update.yml -b'
  end

  desc 'Apt upgrade'
  task :upgrade do
    sh 'ansible-playbook -i hosts playbook/upgrade.yml -b'
  end

  desc 'Apt autoremove --purge'
  task :autoremove do
    sh 'ansible all -i hosts -a "apt-get autoremove --purge -y" -b'
  end
end

namespace :config do
  desc 'Debconf of apt-listchanges'
  task 'apt_listchanges' do
    sh 'ansible-playbook -i hosts playbook/apt-listchanges.yml -b'
  end
  all_tasks.push 'config:apt_listchanges'

  desc 'Create /etc/needrestart/conf.d/50local.conf'
  task :needrestart do
    sh "ansible-playbook -i hosts playbook/needrestart.yml -b"
  end
  all_tasks.push 'config:needrestart'
end

namespace :lima do
  lima_ssh_config = File.expand_path('~/.cache/lima.ssh_config')
  lima_hosts = File.expand_path('~/.cache/lima.hosts')

  desc 'Apt update on lima hosts'
  task update: :ssh_config do
    sh "ansible-playbook -i #{lima_hosts} playbook/update.yml -b"
  end

  desc 'Apt upgrade on lima hosts'
  task upgrade: :ssh_config do
    sh "ansible-playbook -i #{lima_hosts} playbook/upgrade.yml -b"
  end

  task :ssh_config do
    # FIXME: ~/.ssh/config への追加は末尾だとうまく動かないかも
    sh %(grep 'Include #{lima_ssh_config}' ~/.ssh/config || echo 'Include #{lima_ssh_config}' >> ~/.ssh/config)
    sh %(limactl list -f '{{if eq .Status "Running"}}{{.Name}}{{end}}' | xargs -n1 limactl show-ssh --format=config > #{lima_ssh_config})
    sh %(limactl list -f '{{if eq .Status "Running"}}lima-{{.Name}}{{end}}' > #{lima_hosts})
  end

  desc 'Create /etc/needrestart/conf.d/50local.conf'
  task needrestart: :ssh_config do
    sh "ansible-playbook -i #{lima_hosts} playbook/needrestart.yml -b"
  end
  all_tasks.push 'lima:needrestart'
end

namespace :local do
  desc 'ansible.builtin.setup'
  task :setup do
    sh 'ansible localhost -i , -m ansible.builtin.setup'
  end
end

namespace :wg2 do
  desc 'Play wg2'
  task :all do
    sh 'ansible-playbook -i inventories/wg2/hosts playbook/wg2.yml'
  end
  all_tasks.push 'wg2:all'

  desc 'Play wg2 with conf tags only'
  task :conf do
    sh 'ansible-playbook -i inventories/wg2/hosts playbook/wg2.yml --tags wireguard_conf'
  end
end

namespace :chkbuild do
  desc 'Play chkbuild'
  task :all do
    sh 'ansible-playbook -i inventories/chkbuild/hosts playbook/chkbuild.yml'
  end
  all_tasks.push 'chkbuild:all'
end

desc "Run #{all_tasks.join(' ')}"
task all: all_tasks
