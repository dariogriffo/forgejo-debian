# Forgejo

Forgejo is a self-hosted lightweight software forge.
Easy to install and low maintenance, it just does the job.

## Features

- Create and host git repositories
- Manage users, teams and organizations
- Issue tracking, pull requests, code review
- Git LFS support
- Webhook support
- Two-factor authentication
- OAuth2 provider
- Gitea-compatible API

## Documentation

- Website: https://forgejo.org
- Documentation: https://forgejo.org/docs/
- Source code: https://codeberg.org/forgejo/forgejo

## Post-installation

After installation, complete the setup by:

1. Starting the service: `sudo systemctl start forgejo`
2. Opening http://localhost:3000 in your browser
3. Following the web-based initial configuration
4. After setup: `sudo systemctl enable forgejo`

## License

Forgejo is licensed under GPL-3.0-or-later.
