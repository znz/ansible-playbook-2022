.PHONY: phony

setup-at-local: phony
	ansible localhost -i , -m ansible.builtin.setup

apt-listchanges: phony
	ansible-playbook apt-listchanges.yml

ping: phony
	ansible all -i hosts -m ping

update: phony
	ansible-playbook -i hosts playbook/update.yml

upgrade: phony
	ansible-playbook -i hosts playbook/upgrade.yml

play-wg2: phony
	ansible-playbook -i inventories/wg2/hosts playbook/wg2.yml
play-wg2-conf: phony
	ansible-playbook -i inventories/wg2/hosts playbook/wg2.yml --tags wireguard_conf

play-chkbuild: phony
	ansible-playbook -i inventories/chkbuild/hosts playbook/chkbuild.yml

play-needrestart: phony
	ansible-playbook -i inventories/wg2/hosts playbook/needrestart.yml

LIMA_SSH_CONFIG = ~/.cache/lima.ssh_config
LIMA_HOSTS = ~/.cache/lima.hosts

update-lima: update-lima.ssh_config phony
	ansible-playbook -i $(LIMA_HOSTS) playbook/update.yml -b

upgrade-lima: update-lima.ssh_config phony
	ansible-playbook -i $(LIMA_HOSTS) playbook/upgrade.yml -b

# FIXME: ~/.ssh/config への追加は末尾だとうまく動かないかも
update-lima.ssh_config: phony
	grep 'Include $(LIMA_SSH_CONFIG)' ~/.ssh/config || echo 'Include $(LIMA_SSH_CONFIG)' >> ~/.ssh/config
	limactl list -f '{{if eq .Status "Running"}}{{.Name}}{{end}}' | xargs -n1 limactl show-ssh --format=config > $(LIMA_SSH_CONFIG)
	limactl list -f '{{if eq .Status "Running"}}lima-{{.Name}}{{end}}' > $(LIMA_HOSTS)

play-needrestart-lima: update-lima.ssh_config phony
	ansible-playbook -i $(LIMA_HOSTS) playbook/needrestart.yml -b

update-with-pass: phony
	ansible-playbook -i ../hosts playbook/update.yml -b -K

upgrade-with-pass: phony
	ansible-playbook -i ../hosts playbook/upgrade.yml -b -K
