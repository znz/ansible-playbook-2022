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
# TODO: apt -o APT::Get::Always-Include-Phased-Updates=true full-upgrade -V

play-wg2:
	ansible-playbook -i inventories/wg2/hosts wg2.yml
play-wg2-conf:
	ansible-playbook -i inventories/wg2/hosts wg2.yml --tags wireguard_conf

LIMA_SSH_CONFIG = ~/.cache/lima.ssh_config
LIMA_HOSTS = ~/.cache/lima.hosts

update-lima: update-lima.ssh_config
	ansible all -i $(LIMA_HOSTS) -m apt -a "update_cache=yes cache_valid_time=3600" -b

# FIXME: ~/.ssh/config への追加は末尾だとうまく動かないかも
update-lima.ssh_config:
	grep 'Include $(LIMA_SSH_CONFIG)' ~/.ssh/config || echo 'Include $(LIMA_SSH_CONFIG)' >> ~/.ssh/config
	limactl list -f '{{if eq .Status "Running"}}{{.Name}}{{end}}' | xargs -n1 limactl show-ssh --format=config > $(LIMA_SSH_CONFIG)
	limactl list -f '{{if eq .Status "Running"}}lima-{{.Name}}{{end}}' > $(LIMA_HOSTS)
