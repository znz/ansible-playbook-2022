# frozen-string-literal: true

all_tasks = []

namespace :misc do
  desc 'Ping all hosts'
  task :ping, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    sh "ansible all -i #{inventory} -m ping --one-line --forks 20"
  end

  desc 'Show uptime'
  task :uptime, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    sh "ansible all -i #{inventory} -a uptime --one-line --forks 20"
  end

  desc 'Show removed packages'
  task :removed, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    sh "ansible all -i #{inventory} -m shell -a 'dpkg -l | grep \"^rc\"' --forks 20"
  end

  desc 'Show lsb-release -a'
  task :lsb_release, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    require 'open3'
    command = "ansible all -i #{inventory} -a 'lsb_release -a' --one-line --forks 20"
    puts command
    out, status = Open3.capture2 command
    lines = out.lines.map do |line|
      columns = line.split('|')
      columns[0] = columns[0].ljust(20)
      columns
    end.sort_by { _4 }.map do |columns|
      columns.join('|')
    end
    puts lines
  end
end

namespace :nadoka do
  desc 'Restart nadoka'
  task :restart, [:inventory] do |_t, args|
    inventory = args.inventory || 'hosts'
    sh "ansible nadoka -i #{inventory} -m ansible.builtin.systemd -a 'name=nadoka@fprog state=restarted' --one-line -b"
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
    sh "ansible-playbook -i #{inventory} playbook/update.yml -b --forks 20"
    sh "ansible all -i #{inventory} -a 'apt-get full-upgrade --download-only -y' -b --forks 20"
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
  lima_all_tasks = []
  lima_ssh_config = '~/.lima/*/ssh.config'
  # group_vars/nadoka.yml のために hosts と同じところに作成
  lima_hosts = File.expand_path('lima.hosts', __dir__)

  task :ssh_config do
    # FIXME: ~/.ssh/config への追加は末尾だとうまく動かないかも
    sh %(grep -F 'Include #{lima_ssh_config}' ~/.ssh/config || echo 'Include #{lima_ssh_config}' >> ~/.ssh/config)
    cond = 'eq .Status "Running"'
    sh %(echo '[lima]' > #{lima_hosts})
    sh %(limactl list -f '{{if #{cond}}}lima-{{.Name}} ansible_ssh_user=ansible-runner{{end}}' >> #{lima_hosts})
    File.open(lima_hosts, 'a') do |f|
      f.puts <<~HOSTS
        [ufw]
        lima-default
        [zabbix_agent]
        # lima-default
        [conoha_u01_lxd_instance]
        # empty group for playbook/ufw.yml

        [nadoka:children]
        lima
        [apt_update:children]
        lima
        [apt_upgrade:children]
        lima
      HOSTS
    end
  end

  [
    %i[misc ping],
    %i[misc uptime],
    %i[apt update],
    %i[apt upgrade],
    %i[apt autoremove],
    %i[config apt_listchanges],
    %i[config needrestart],
    %i[play ufw],
    %i[play nadoka],
    %i[play zabbix-agent],
  ].each do |namespace, task_name|
    desc "#{namespace}:#{task_name} for lima"
    task task_name => :ssh_config do |t|
      Rake::Task["#{namespace}:#{task_name}"].invoke lima_hosts
    end
    lima_all_tasks.push "lima:#{task_name}"
  end

  desc 'Play lima cookbook'
  task play: :ssh_config do
    sh "ansible-playbook -i #{lima_hosts} playbook/lima.yml -b"
  end

  desc "Run #{lima_all_tasks.join(' ')}"
  task all: lima_all_tasks
end

# Prepare:
#  machinectl shell $NAME /usr/bin/apt install openssh-server python3 sudo -y
#  machinectl shell $NAME /usr/bin/install -m 700 -d /root/.ssh
#  machinectl copy-to $NAME ~/.ssh/authorized_keys /root/.ssh/authorized_keys
# Firewall:
#  ufw allow in on ve-+ from any port 68 to 0.0.0.0/0 port 67 proto udp comment 'DHCPv4 from nspawn'
#  ufw allow out on ve-+ from 0.0.0.0/0 port 67 to any port 68 proto udp comment 'DHCPv4 to nspawn'
namespace :nspawn do
  nspawn_all_tasks = []

  task :ssh_config, [:machine_manager] do |_t, args|
    machine_manager = args.fetch(:machine_manager) { ENV.fetch('MACHINE_MANAGER') }
    nspawn_json = File.expand_path("~/.cache/machinectl_list.#{machine_manager}.json")
    nspawn_ssh_config_basename = "nspawn.#{machine_manager}.ssh_config"
    nspawn_ssh_config = File.expand_path("~/.cache/#{nspawn_ssh_config_basename}")
    nspawn_hosts = File.expand_path("~/.cache/nspawn.#{machine_manager}.hosts")

    sh %(grep 'Include .*#{nspawn_ssh_config_basename}' ~/.ssh/config || echo 'Include #{nspawn_ssh_config}' >> ~/.ssh/config)

    sh %(ssh #{machine_manager} machinectl list -o json > #{nspawn_json})
    require 'json'
    list = JSON.load_file(nspawn_json)

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
    %i[misc ping],
    %i[misc uptime],
    %i[apt update],
    %i[apt upgrade],
    %i[apt autoremove],
    %i[config apt_listchanges],
    %i[config needrestart],
  ].each do |namespace, task_name|
    desc "#{namespace}:#{task_name} for nspawn"
    task task_name => :ssh_config do |_t, args|
      machine_manager = args.fetch(:machine_manager) { ENV.fetch('MACHINE_MANAGER') }
      nspawn_hosts = File.expand_path("~/.cache/nspawn.#{machine_manager}.hosts")
      Rake::Task["#{namespace}:#{task_name}"].invoke nspawn_hosts
    end
    nspawn_all_tasks.push "nspawn:#{task_name}"
  end

  desc "Run #{nspawn_all_tasks.join(' ')}"
  task all: nspawn_all_tasks
end

namespace :local do
  desc 'ansible.builtin.setup'
  task :setup do
    sh 'ansible localhost -i , -m ansible.builtin.setup'
  end
end

Dir.glob('inventories/wg*') do |inventory|
  wg = File.basename(inventory)

  namespace wg do
    if File.exist?("playbook/#{wg}.yml")
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

    if File.exist?("playbook/#{wg}-coredns.yml")
      desc "Play coredns for #{wg}"
      task :coredns do
        # https://docs.ansible.com/ansible/latest/reference_appendices/faq.html#running-on-macos
        env = { 'OBJC_DISABLE_INITIALIZE_FORK_SAFETY' => 'YES' }
        sh env, "ansible-playbook -i inventories/#{wg}/hosts playbook/#{wg}-coredns.yml"
      end

      all_tasks.push "#{wg}:coredns"
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

namespace :remote_dev do
  desc 'Play remote-dev-env'
  task :all do
    sh 'ansible-playbook -i inventories/remote-dev/hosts playbook/remote-dev-env.yml'
  end

  desc 'Play ruby-build from here'
  task :here do
    sh 'ansible-playbook -i inventories/remote-dev/hosts playbook/remote-dev-env.yml --start-at-task "here"'
  end
  all_tasks.push 'ruby_build:all'
end

namespace :ruby_build do
  desc 'Play ruby-build'
  task :all do
    sh 'ansible-playbook -i inventories/ruby-build/hosts playbook/ruby-build.yml'
  end

  desc 'Play ruby-build for updating scripts'
  task :scripts do
    sh 'ansible-playbook -i inventories/ruby-build/hosts playbook/ruby-build.yml --start-at-task "Create rbenv-install-stable-versions"'
  end
  all_tasks.push 'ruby_build:all'
end

namespace :zabbix do
  desc 'Play zabbix-server'
  task :server do
    sh 'ansible-playbook -i inventories/zabbix-server/hosts playbook/zabbix-server.yml'
  end

  #all_tasks.push 'zabbix:server'
end

desc "Run #{all_tasks.join(' ')}"
task all: all_tasks

namespace :play do
  %i[
    ufw
    nadoka
    lxd
    zabbix-agent
    btrfsmaintenance
    btrbk
    backup_to_btrbk
  ].each do |name|
    desc "Play #{name}"
    task name, [:inventory] do |_t, args|
      inventory = args.inventory || 'hosts'
      sh "ansible-playbook -i #{inventory} playbook/#{name}.yml"
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
