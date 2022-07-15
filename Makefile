setup-at-local:
	ansible localhost -i , -m ansible.builtin.setup

apt-listchanges:
	ansible-playbook apt-listchanges.yml
