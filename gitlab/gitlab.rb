# URL link
external_url 'https://gitlabs.alprojects.org'

# SSH port
gitlab_rails['gitlab_shell_ssh_port'] = 3200


# Disabling Gitlab Process
letsencrypt['auto_renew'] = false


# Traefik will terminate
nginx['listen_port'] = 80
nginx['listen_https'] = false

