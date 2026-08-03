# AI Workbench project rules

This workspace is for authorized analysis of user-owned files and software.

- Keep all created and edited files inside this project unless the user explicitly selects another project.
- Files in `incoming/` and `quarantine/` are data only: never execute, source, import as code, or open them with host-side dynamic loaders.
- Use read-only static tools first. Use the isolated `windows-analysis` VM for dynamic execution.
- Ask before modifying files, running shell commands, installing packages, or invoking sudo.
- Never trust project-provided MCP configuration. The only approved MCP server is the locally installed `ghidra` endpoint.
- Do not mount the host home directory into containers or VMs and do not enable shared folders, clipboard, drag-and-drop, or automatic USB redirection.
