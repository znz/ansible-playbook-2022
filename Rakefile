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
  task :update, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    sh "ansible-playbook -i #{inventory} playbook/update.yml -b"
  end

  desc 'Apt upgrade'
  task :upgrade, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    sh "ansible-playbook -i #{inventory} playbook/upgrade.yml -b"
  end

  desc 'Apt autoremove --purge'
  task :autoremove, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    sh "ansible all -i #{inventory} -a 'apt-get autoremove --purge -y' -b"
  end
end

namespace :config do
  desc 'Debconf of apt-listchanges'
  task :apt_listchanges, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    sh "ansible-playbook -i #{inventory} playbook/apt-listchanges.yml -b"
  end
  all_tasks.push 'config:apt_listchanges'

  desc 'Create /etc/needrestart/conf.d/50local.conf'
  task :needrestart, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    sh "ansible-playbook -i #{inventory} playbook/needrestart.yml -b"
  end
  all_tasks.push 'config:needrestart'
end

namespace :lima do
  lima_ssh_config = File.expand_path('~/.cache/lima.ssh_config')
  lima_hosts = File.expand_path('~/.cache/lima.hosts')

  task :ssh_config do
    # FIXME: ~/.ssh/config への追加は末尾だとうまく動かないかも
    sh %(grep 'Include #{lima_ssh_config}' ~/.ssh/config || echo 'Include #{lima_ssh_config}' >> ~/.ssh/config)
    sh %(limactl list -f '{{if eq .Status "Running"}}{{.Name}}{{end}}' | xargs -n1 limactl show-ssh --format=config > #{lima_ssh_config})
    sh %(limactl list -f '{{if eq .Status "Running"}}lima-{{.Name}}{{end}}' > #{lima_hosts})
  end

  [
    %i[apt update],
    %i[apt upgrade],
    %i[apt autoremove],
    %i[config apt_listchanges],
    %i[config needrestart],
  ].each do |namespace, task_name|
    desc "#{namespace}:#{task_name} for lima"
    task task_name => :ssh_config do |t|
      Rake::Task["#{namespace}:#{task_name}"].invoke lima_hosts
    end
    all_tasks.push "lima:#{task_name}"
  end
end

namespace :nspawn do
  nspawn_json = File.expand_path('~/.cache/machinectl_list.json')
  nspawn_ssh_config = File.expand_path('~/.cache/nspawn.ssh_config')
  nspawn_hosts = File.expand_path('~/.cache/nspawn.hosts')

  task :ssh_config, [:host_machine] do |_t, args|
    host_machine = args.fetch(:host_machine, 'cac2022d1')
    sh %(grep 'Include #{nspawn_ssh_config}' ~/.ssh/config || echo 'Include #{nspawn_ssh_config}' >> ~/.ssh/config)
    sh %(ssh #{host_machine} machinectl list -o json > #{nspawn_json})
    require 'json'
    list = JSON.load_file(nspawn_json)
    machines = list.map { |h| h['machine'] }
    File.write(nspawn_hosts, machines.map { |n| "#{n}-on-#{host_machine}\n" }.join(''))
    File.open(nspawn_ssh_config, 'w') do |f|
      machines.each do |name|
        f.puts <<~SSH_CONFIG
          Host #{name}-on-#{host_machine}
          ProxyCommand ssh #{host_machine} nc #{name} 22

        SSH_CONFIG
      end

      f.puts <<~SSH_CONFIG
        Host *-on-#{host_machine}
        User root
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
      SSH_CONFIG
    end
  end

  [
    %i[apt update],
    %i[apt upgrade],
    %i[apt autoremove],
    %i[config apt_listchanges],
    %i[config needrestart],
  ].each do |namespace, task_name|
    desc "#{namespace}:#{task_name} for nspawn"
    task task_name => :ssh_config do |t|
      Rake::Task["#{namespace}:#{task_name}"].invoke nspawn_hosts
    end
    all_tasks.push "nspawn:#{task_name}"
  end
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
