const express = require('express');
const WebSocket = require('ws');
const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Server configuration
const SERVERS = [
    {
        name: 'azazello',
        host: 'azazello.raxla.org',
        ip: '91.242.163.206',
        description: 'Czech external gateway',
        critical_services: ['xray', 'x-ui', 'nginx', 'fail2ban', 'docker'],
        critical_ports: [443, 9443, 2020],
        role: 'exit-node'
    },
    {
        name: 'hometele',
        host: 'hometele.com.ru',
        ip: '185.71.196.110',
        description: 'Russian entry point',
        critical_services: ['xray', 'postfix', 'nginx', 'fail2ban'],
        critical_ports: [443, 80],
        role: 'entry-node'
    },
    {
        name: 'www',
        host: 'www.hometele.com.ru',
        ip: '93.183.106.203',
        description: 'Service node - Matrix, Git-WIKI',
        critical_services: ['matrix-synapse', 'nginx', 'coturn', 'hometele-command-agent'],
        critical_ports: [8008, 8080, 5349, 80, 443],
        role: 'service-node'
    }
];

const SSH_CONFIG = {
    port: 52000,
    username: process.env.SSH_USER || 'suazzzi',
    privateKeyPath: process.env.SSH_KEY_PATH || path.join(process.env.USERPROFILE || process.env.HOME, '.ssh', 'id_rsa'),
    tryKeyboard: false,
    readyTimeout: 10000
};

// WebSocket server
const server = app.listen(PORT, () => {
    console.log(`\n╔════════════════════════════════════════════════════════════════╗`);
    console.log(`║   VPN Infrastructure Monitor - Server Running                  ║`);
    console.log(`╚════════════════════════════════════════════════════════════════╝\n`);
    console.log(`🌐 Web Interface: http://localhost:${PORT}`);
    console.log(`🔌 WebSocket: ws://localhost:${PORT}`);
    console.log(`📊 Monitoring ${SERVERS.length} servers`);
    console.log(`🔑 SSH Port: ${SSH_CONFIG.port}`);
    console.log(`👤 SSH User: ${SSH_CONFIG.username}\n`);
});

const wss = new WebSocket.Server({ server });

// Store active connections
const clients = new Set();

wss.on('connection', (ws) => {
    console.log('✓ New client connected');
    clients.add(ws);

    ws.on('message', async (message) => {
        try {
            const data = JSON.parse(message);
            console.log(`📨 Received: ${data.type}`);

            switch (data.type) {
                case 'monitor':
                    await handleMonitor(ws, data.servers || SERVERS.map(s => s.name));
                    break;
                case 'command':
                    await handleCommand(ws, data);
                    break;
                case 'config':
                    ws.send(JSON.stringify({ type: 'config', servers: SERVERS }));
                    break;
                default:
                    ws.send(JSON.stringify({ type: 'error', message: 'Unknown command' }));
            }
        } catch (error) {
            console.error('Error handling message:', error);
            ws.send(JSON.stringify({ type: 'error', message: error.message }));
        }
    });

    ws.on('close', () => {
        console.log('✗ Client disconnected');
        clients.delete(ws);
    });

    // Send initial config
    ws.send(JSON.stringify({ type: 'config', servers: SERVERS }));
});

// SSH connection helper
async function connectSSH(serverName) {
    const server = SERVERS.find(s => s.name === serverName);
    if (!server) {
        throw new Error(`Server ${serverName} not found`);
    }

    const ssh = new NodeSSH();

    try {
        await ssh.connect({
            host: server.host,
            port: SSH_CONFIG.port,
            username: SSH_CONFIG.username,
            privateKeyPath: SSH_CONFIG.privateKeyPath,
            readyTimeout: SSH_CONFIG.readyTimeout
        });
        return ssh;
    } catch (error) {
        console.error(`SSH connection failed to ${serverName}:`, error.message);
        throw error;
    }
}

// Deploy health check script
async function deployHealthCheckScript(ssh, serverName) {
    const scriptPath = path.join(__dirname, 'server-health-check.sh');
    const scriptContent = fs.readFileSync(scriptPath, 'utf8');

    // Upload script
    await ssh.execCommand(`cat > /tmp/server-health-check.sh << 'EOFSCRIPT'\n${scriptContent}\nEOFSCRIPT\n`);
    await ssh.execCommand('chmod +x /tmp/server-health-check.sh');
}

// Monitor servers
async function handleMonitor(ws, serverNames) {
    for (const serverName of serverNames) {
        const server = SERVERS.find(s => s.name === serverName);
        if (!server) continue;

        ws.send(JSON.stringify({
            type: 'status',
            server: serverName,
            status: 'connecting'
        }));

        try {
            const ssh = await connectSSH(serverName);

            ws.send(JSON.stringify({
                type: 'status',
                server: serverName,
                status: 'connected'
            }));

            // Deploy script if needed
            const checkScript = await ssh.execCommand('[ -f /tmp/server-health-check.sh ] && echo "exists"');
            if (!checkScript.stdout.includes('exists')) {
                await deployHealthCheckScript(ssh, serverName);
            }

            // Run health check
            const result = await ssh.execCommand(`/tmp/server-health-check.sh ${serverName}`);

            if (result.code === 0) {
                const healthData = JSON.parse(result.stdout);

                ws.send(JSON.stringify({
                    type: 'health',
                    server: serverName,
                    data: healthData,
                    timestamp: new Date().toISOString()
                }));
            } else {
                throw new Error(result.stderr || 'Health check failed');
            }

            ssh.dispose();
        } catch (error) {
            console.error(`Monitor error for ${serverName}:`, error.message);

            ws.send(JSON.stringify({
                type: 'error',
                server: serverName,
                message: error.message,
                timestamp: new Date().toISOString()
            }));
        }
    }
}

// Handle commands (restart service, run Matrix commands, etc)
async function handleCommand(ws, data) {
    const { server: serverName, command, args } = data;
    const server = SERVERS.find(s => s.name === serverName);

    if (!server) {
        ws.send(JSON.stringify({
            type: 'command-result',
            success: false,
            message: `Server ${serverName} not found`
        }));
        return;
    }

    ws.send(JSON.stringify({
        type: 'command-status',
        server: serverName,
        command,
        status: 'executing'
    }));

    try {
        const ssh = await connectSSH(serverName);
        let result;

        switch (command) {
            case 'restart-service':
                result = await ssh.execCommand(`sudo systemctl restart ${args.service}`);
                break;

            case 'service-status':
                result = await ssh.execCommand(`systemctl status ${args.service} --no-pager -l`);
                break;

            case 'fail2ban-status':
                result = await ssh.execCommand('sudo fail2ban-client status');
                break;

            case 'ports-check':
                result = await ssh.execCommand('ss -lntup');
                break;

            case 'vpn-list':
                if (serverName === 'hometele') {
                    result = await ssh.execCommand('/usr/local/sbin/hometele-vpn-user list');
                } else {
                    throw new Error('VPN commands only available on hometele');
                }
                break;

            case 'vpn-add':
                if (serverName === 'hometele') {
                    result = await ssh.execCommand(`/usr/local/sbin/hometele-vpn-user add ${args.username}`);
                } else {
                    throw new Error('VPN commands only available on hometele');
                }
                break;

            case 'vpn-del':
                if (serverName === 'hometele') {
                    result = await ssh.execCommand(`/usr/local/sbin/hometele-vpn-user del ${args.username}`);
                } else {
                    throw new Error('VPN commands only available on hometele');
                }
                break;

            case 'custom':
                // Execute custom command (dangerous - should be restricted in production)
                result = await ssh.execCommand(args.cmd);
                break;

            default:
                throw new Error(`Unknown command: ${command}`);
        }

        ssh.dispose();

        ws.send(JSON.stringify({
            type: 'command-result',
            server: serverName,
            command,
            success: result.code === 0,
            stdout: result.stdout,
            stderr: result.stderr,
            timestamp: new Date().toISOString()
        }));

    } catch (error) {
        console.error(`Command error for ${serverName}:`, error.message);

        ws.send(JSON.stringify({
            type: 'command-result',
            server: serverName,
            command,
            success: false,
            message: error.message,
            timestamp: new Date().toISOString()
        }));
    }
}

// REST API endpoints
app.get('/api/servers', (req, res) => {
    res.json({ servers: SERVERS });
});

app.get('/api/health/:server', async (req, res) => {
    const serverName = req.params.server;

    try {
        const ssh = await connectSSH(serverName);

        // Check if script exists
        const checkScript = await ssh.execCommand('[ -f /tmp/server-health-check.sh ] && echo "exists"');
        if (!checkScript.stdout.includes('exists')) {
            await deployHealthCheckScript(ssh, serverName);
        }

        const result = await ssh.execCommand(`/tmp/server-health-check.sh ${serverName}`);
        ssh.dispose();

        if (result.code === 0) {
            const healthData = JSON.parse(result.stdout);
            res.json({ success: true, data: healthData });
        } else {
            res.status(500).json({ success: false, error: result.stderr });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.post('/api/command/:server', async (req, res) => {
    const serverName = req.params.server;
    const { command, args } = req.body;

    try {
        const ssh = await connectSSH(serverName);
        let result;

        // Execute command based on type
        switch (command) {
            case 'service-status':
                result = await ssh.execCommand(`systemctl status ${args.service} --no-pager -l`);
                break;
            default:
                throw new Error('Command not allowed via REST API');
        }

        ssh.dispose();

        res.json({
            success: result.code === 0,
            stdout: result.stdout,
            stderr: result.stderr
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Broadcast to all clients
function broadcast(data) {
    clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    });
}

// Auto-refresh monitoring (every 60 seconds)
let autoRefreshInterval = null;

app.post('/api/auto-refresh', (req, res) => {
    const { enabled, interval = 60 } = req.body;

    if (enabled) {
        if (autoRefreshInterval) {
            clearInterval(autoRefreshInterval);
        }

        autoRefreshInterval = setInterval(async () => {
            console.log('🔄 Auto-refresh: monitoring all servers...');

            for (const server of SERVERS) {
                try {
                    const ssh = await connectSSH(server.name);
                    const result = await ssh.execCommand(`/tmp/server-health-check.sh ${server.name}`);
                    ssh.dispose();

                    if (result.code === 0) {
                        const healthData = JSON.parse(result.stdout);

                        broadcast({
                            type: 'health',
                            server: server.name,
                            data: healthData,
                            timestamp: new Date().toISOString()
                        });
                    }
                } catch (error) {
                    console.error(`Auto-refresh error for ${server.name}:`, error.message);

                    broadcast({
                        type: 'error',
                        server: server.name,
                        message: error.message,
                        timestamp: new Date().toISOString()
                    });
                }
            }
        }, interval * 1000);

        res.json({ success: true, message: `Auto-refresh enabled (${interval}s)` });
    } else {
        if (autoRefreshInterval) {
            clearInterval(autoRefreshInterval);
            autoRefreshInterval = null;
        }
        res.json({ success: true, message: 'Auto-refresh disabled' });
    }
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n\n🛑 Shutting down server...');
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
    }
    wss.close(() => {
        server.close(() => {
            console.log('✓ Server closed');
            process.exit(0);
        });
    });
});

console.log('⏳ Waiting for connections...\n');
