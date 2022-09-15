# frozen-string-literal: true

desc 'Ping all hosts'
task :ping do
  sh 'ansible all -i hosts -m ping'
end

# example:
#  rake 'ansible_runner[ns9]'
desc 'Add ansible-runner'
task :ansible_runner, [:host] do |_t, args|
  sh "ansible-playbook -i #{args.to_a.join(',')}, playbook/ansible-user.yml"
end

# example:
#  rake 'ansible_runner_with_pass[ns8,ns6]'
desc 'Add ansible-runner with become password'
task :ansible_runner_with_pass, [:host] do |_t, args|
  sh "ansible-playbook -i #{args.to_a.join(',')}, playbook/ansible-user.yml -b -K"
end

desc 'Apt update'
task :update do
  sh 'ansible-playbook -i hosts playbook/update.yml -b'
end

desc 'Apt upgrade'
task :upgrade do
  sh 'ansible-playbook -i hosts playbook/upgrade.yml -b'
end
