module.exports = {
	apps: [
		{
			name: 'manar',
			script: '/usr/local/bin/manar-server',
			interpreter: '/bin/bash',
			cwd: '/opt/manar',
			autorestart: true,
			restart_delay: 3000,
			env: {
				NODE_ENV: 'production',
				HOST: '127.0.0.1',
				PORT: '3000',
				ORIGIN: '',
				HOST_HEADER: 'x-forwarded-host',
				PROTOCOL_HEADER: 'x-forwarded-proto',
				BODY_SIZE_LIMIT: '210M'
			}
		}
	]
};
