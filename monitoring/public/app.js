// VPN Infrastructure Monitor - Client Application
let ws = null;
let servers = [];
let serverData = {};
let autoRefreshEnabled = false;

// Initialize WebSocket connection
function initWebSocket() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}`;

    ws = new WebSocket(wsUrl);

    ws.onopen = () => {
        log('WebSocket connected', 'success');
        updateConnectionStatus(true);
        ws.send(JSON.stringify({ type: 'config' }));
    };

    ws.onmessage = (event) => {
        const message = JSON.parse(event.data);
        handleMessage(message);
    };

    ws.onclose = () => {
        log('WebSocket disconnected', 'error');
        updateConnectionStatus(false);
        setTimeout(initWebSocket, 3000);
    };

    ws.onerror = (error) => {
        log('WebSocket error', 'error');
    };
}

function handleMessage(message) {
    switch (message.type) {
        case 'config':
            servers = message.servers;
            renderServers();
            break;
        case 'health':
            serverData[message.server] = message.data;
            updateServerCard(message.server, message.data);
            log(`Health data received from ${message.server}`, 'success');
            break;
        case 'error':
            log(`Error from ${message.server}: ${message.message}`, 'error');
            break;
        case 'status':
            log(`${message.server}: ${message.status}`, 'info');
            break;
        case 'command-result':
            handleCommandResult(message);
            break;
    }
}

function renderServers() {
    const grid = document.getElementById('serversGrid');
    grid.innerHTML = servers.map(server => createServerCard(server)).join('');
}

function createServerCard(server) {
    return `
        <div class="server-card" id="card-${server.name}">
            <div class="server-header">
                <div>
                    <div class="server-name">${server.name}</div>
                    <div class="server-info">${server.description}</div>
                    <div class="server-info">${server.ip}</div>
                </div>
                <div class="badge-online">● Online</div>
            </div>

            <div class="metrics-section">
                <h3>System Resources</h3>
                <div class="metric-row">
                    <span>Uptime</span>
                    <span id="${server.name}-uptime">-</span>
                </div>
                <div class="metric-row">
                    <span>CPU Usage</span>
                    <span id="${server.name}-cpu">-</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill progress-ok" id="${server.name}-cpu-bar" style="width: 0%"></div>
                </div>
                <div class="metric-row">
                    <span>Memory</span>
                    <span id="${server.name}-memory">-</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill progress-ok" id="${server.name}-memory-bar" style="width: 0%"></div>
                </div>
                <div class="metric-row">
                    <span>Disk</span>
                    <span id="${server.name}-disk">-</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill progress-ok" id="${server.name}-disk-bar" style="width: 0%"></div>
                </div>
            </div>

            <div class="metrics-section">
                <h3>Services</h3>
                <div class="services-grid" id="${server.name}-services">
                    <div class="loading">Loading...</div>
                </div>
            </div>

            <div class="server-actions">
                <button class="btn btn-primary btn-sm" onclick="refreshServer('${server.name}')">🔄 Refresh</button>
                <button class="btn btn-secondary btn-sm" onclick="openCommandModal('${server.name}')">⚙️ Commands</button>
            </div>
        </div>
    `;
}

function updateServerCard(serverName, data) {
    document.getElementById(`${serverName}-uptime`).textContent = data.system.uptime;
    document.getElementById(`${serverName}-cpu`).textContent = data.system.cpu_usage;

    const cpuPct = parseFloat(data.system.cpu_usage);
    updateProgressBar(`${serverName}-cpu-bar`, cpuPct);

    const memUsage = data.system.memory.usage;
    document.getElementById(`${serverName}-memory`).textContent = memUsage;
    const memPct = parseFloat(memUsage);
    updateProgressBar(`${serverName}-memory-bar`, memPct);

    const diskUsage = data.system.disk.usage;
    document.getElementById(`${serverName}-disk`).textContent = diskUsage;
    const diskPct = parseFloat(diskUsage);
    updateProgressBar(`${serverName}-disk-bar`, diskPct);

    const servicesHtml = data.services.systemd.map(svc => {
        const statusClass = svc.status === 'active' ? 'service-active' : 'service-inactive';
        return `<div class="service-item ${statusClass}">${svc.name}<br><small>${svc.status}</small></div>`;
    }).join('');

    document.getElementById(`${serverName}-services`).innerHTML = servicesHtml;
}

function updateProgressBar(id, percentage) {
    const bar = document.getElementById(id);
    bar.style.width = `${percentage}%`;

    bar.classList.remove('progress-ok', 'progress-warn', 'progress-danger');
    if (percentage < 70) {
        bar.classList.add('progress-ok');
    } else if (percentage < 85) {
        bar.classList.add('progress-warn');
    } else {
        bar.classList.add('progress-danger');
    }
}

function refreshServer(serverName) {
    log(`Refreshing ${serverName}...`, 'info');
    ws.send(JSON.stringify({
        type: 'monitor',
        servers: [serverName]
    }));
}

function refreshAll() {
    log('Refreshing all servers...', 'info');
    ws.send(JSON.stringify({
        type: 'monitor',
        servers: servers.map(s => s.name)
    }));
}

function toggleAutoRefresh() {
    autoRefreshEnabled = !autoRefreshEnabled;
    const btn = document.getElementById('autoRefreshBtn');
    btn.textContent = autoRefreshEnabled ? '⏱️ Auto: ON' : '⏱️ Auto: OFF';

    fetch('/api/auto-refresh', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ enabled: autoRefreshEnabled, interval: 60 })
    });

    log(`Auto-refresh ${autoRefreshEnabled ? 'enabled' : 'disabled'}`, 'info');
}

function updateConnectionStatus(connected) {
    const status = document.getElementById('connectionStatus');
    if (connected) {
        status.textContent = '🟢 Connected';
        status.classList.add('connected');
    } else {
        status.textContent = '🔴 Disconnected';
        status.classList.remove('connected');
    }
}

function log(message, type = 'info') {
    const logsContent = document.getElementById('logsContent');
    const time = new Date().toLocaleTimeString();
    const entry = document.createElement('div');
    entry.className = `log-entry ${type}`;
    entry.innerHTML = `<span class="log-time">[${time}]</span> ${message}`;
    logsContent.appendChild(entry);
    logsContent.scrollTop = logsContent.scrollHeight;
}

function openCommandModal(serverName) {
    const modal = document.getElementById('commandModal');
    document.getElementById('modalServerName').textContent = serverName;
    modal.style.display = 'block';

    document.getElementById('executeBtn').onclick = () => executeCommand(serverName);
}

function executeCommand(serverName) {
    const commandType = document.getElementById('commandType').value;
    const args = {};

    if (commandType === 'service-status' || commandType === 'restart-service') {
        const serviceName = prompt('Enter service name (e.g., xray, nginx):');
        if (!serviceName) return;
        args.service = serviceName;
    } else if (commandType === 'vpn-add' || commandType === 'vpn-del') {
        const username = prompt('Enter VPN username:');
        if (!username) return;
        args.username = username;
    }

    log(`Executing ${commandType} on ${serverName}...`, 'info');

    ws.send(JSON.stringify({
        type: 'command',
        server: serverName,
        command: commandType,
        args: args
    }));
}

function handleCommandResult(message) {
    const resultDiv = document.getElementById('commandResult');

    if (message.success) {
        resultDiv.innerHTML = `<pre style="color: var(--success-color);">${message.stdout || 'Command executed successfully'}</pre>`;
        log(`Command on ${message.server} succeeded`, 'success');
    } else {
        resultDiv.innerHTML = `<pre style="color: var(--danger-color);">${message.stderr || message.message}</pre>`;
        log(`Command on ${message.server} failed`, 'error');
    }
}

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
    initWebSocket();

    document.getElementById('refreshBtn').onclick = refreshAll;
    document.getElementById('autoRefreshBtn').onclick = toggleAutoRefresh;
    document.getElementById('clearLogsBtn').onclick = () => {
        document.getElementById('logsContent').innerHTML = '';
    };

    const modal = document.getElementById('commandModal');
    document.querySelector('.close').onclick = () => {
        modal.style.display = 'none';
    };

    window.onclick = (event) => {
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    };
});
