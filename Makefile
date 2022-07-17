setup-at-local:
	ansible localhost -i , -m ansible.builtin.setup

apt-listchanges:
	ansible-playbook apt-listchanges.yml

ping:
	ansible all -i hosts -m ping

update:
	ansible all -i hosts -m apt -a "update_cache=yes cache_valid_time=3600"

upgrade:
	ansible all -i hosts -m apt -a "upgrade=full purge=yes autoremove=yes"
	ansible all -i hosts -m command -a '[ ! -f /run/reboot-required ]'
# apt -o APT::Get::Always-Include-Phased-Updates=true full-upgrade -V
