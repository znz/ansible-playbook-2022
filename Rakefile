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

# Prepare:
#  machinectl shell $NAME /usr/bin/apt install openssh-server python3 sudo -y
#  machinectl shell $NAME /usr/bin/install -m 700 -d /root/.ssh
#  machinectl copy-to $NAME ~/.ssh/authorized_keys /root/.ssh/authorized_keys
namespace :nspawn do
  nspawn_json = File.expand_path('~/.cache/machinectl_list.json')
  nspawn_ssh_config = File.expand_path('~/.cache/nspawn.ssh_config')
  nspawn_hosts = File.expand_path('~/.cache/nspawn.hosts')

  task :ssh_config, [:machine_manager] do |_t, args|
    machine_manager = args.fetch(:machine_manager) { ENV.fetch('MACHINE_MANAGER') }
    sh %(grep 'Include #{nspawn_ssh_config}' ~/.ssh/config || echo 'Include #{nspawn_ssh_config}' >> ~/.ssh/config)
    sh %(ssh #{machine_manager} machinectl list -o json > #{nspawn_json})
    require 'json'
    list = JSON.load_file(nspawn_json)
    machines = list.map { |h| h['machine'] }

    hosts = list.map do |h|
      name = h['machine']
      case name
      when /\bsid\b/
        "#{name}.#{machine_manager} ansible_python_interpreter=auto_silent\n"
      else
        "#{name}.#{machine_manager}\n"
      end
    end
    File.write(nspawn_hosts, hosts.join(''))
    File.open(nspawn_ssh_config, 'w') do |f|
      list.map do |h|
        name = h['machine']

        f.puts <<~SSH_CONFIG
          Host #{name}.#{machine_manager}
          Hostname #{name}

        SSH_CONFIG
      end

      f.puts <<~SSH_CONFIG
        Host *.#{machine_manager}
        ProxyCommand ssh -W %h:%p -q #{machine_manager}
        StrictHostKeyChecking no
        User root
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

%i[
  wg2
  wg2022
].each do |wg|
  namespace wg do
    desc "Play wireguard for #{wg}"
    task :all do
      sh "ansible-playbook -i inventories/#{wg}/hosts playbook/#{wg}.yml"
    end
    all_tasks.push "#{wg}:all"

    desc "Update conf of #{wg}"
    task :conf do
      sh "ansible-playbook -i inventories/#{wg}/hosts playbook/#{wg}.yml --tags wireguard_conf"
    end

    desc "Update /etc/hosts for #{wg}"
    task :hosts do
      sh "ansible-playbook -i inventories/#{wg}/hosts playbook/#{wg}.yml --tags wireguard_etc_hosts"
    end
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

namespace :play do
  %i[
    ufw
    nadoka
  ].each do |name|
    desc "Play #{name}"
    task name do
      sh "ansible-playbook -i hosts playbook/#{name}.yml"
    end
    all_tasks.push "play:#{name}"
  end
end

directory 'group_vars'
directory 'playbook/tmp'

file 'group_vars/nadoka.yml' => %w[group_vars playbook/tmp] do |t|
  sh "bw get item 'nadoka (fprog)' > playbook/tmp/nadoka.json"
  require 'json'
  json = JSON.load_file('playbook/tmp/nadoka.json')
  fields = json['login'].dup
  json['fields'].each do |h|
    fields[h['name']] = h['value']
  end
  File.write(t.name, <<-YAML + <<-'YAML')
---
nadoka:
- service_name: "fprog"
  irc_host: "#{fields['host']}"
  irc_port: "#{fields['port']}"
  irc_pass: "'#{fields['pass']}'"
  irc_ssl_params: '{}'
  irc_nick: "User"
  channel_info: |
    #{fields['channel_info']}
YAML
  more_config: |
    if system('docker', 'ps', %i[out err]=>File::NULL)
      require 'open3'
      BotConfig << {
        :name => :WatchBot,
        :channels => %w"#servers",
        :command => proc {
          out, status = Open3.capture2e('docker', 'ps', '--format', "{\{.ID\}}\\t{\{.CreatedAt\}}\\t{\{.Image\}}\\t{\{.Names\}}\\t{\{.Command\}}")
          out = out.split(/\n/)
          unless status.success?
            out << status.inspect
          end
          out
        },
        :min_interval => 60,
      }
    end
  YAML
end

task 'play:nadoka' => 'group_vars/nadoka.yml'

desc "Run #{all_tasks.join(' ')}"
task all: all_tasks
