# frozen-string-literal: true

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

task all: %w[ansible:user]

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
end
