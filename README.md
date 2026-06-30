# Info-Bar

Arch Linux System Utilities & InfoBar
A collection of lightweight Bash scripts designed to keep your Arch Linux system lean, optimized, and paired with a custom desktop widgets layer via Quickshell.

🛠️ Included Tools
1. Arch System Maintenance & Cleanup (arch-sysclean.sh)
An interactive, safe, and transparent optimization script for Arch Linux. It breaks down exactly what it is doing before executing any commands, giving you total control over what gets deleted.

Orphan Package Purging: Scans for and removes unneeded dependencies (pacman -Qdtq).

Redundant Software Stack Removal: Targets leftover VM integration tools, development compilers, and unused networking/mirror tools.

Systemd Timer Auditing: Automatically cleans up orphaned systemd hooks (like lingering reflector timers).

Pacman Cache Optimization: Safely trims your package cache down to the last 2 versions while completely purging uninstalled apps (paccache).

Journal Log Vacuuming: Shrinks runaway systemd journal logs down to a clean 200MB ceiling.

Storage Recovery Metrics: Calculates and prints exactly how much space (MB or GB) you recovered at the end of the run.

2. InfoBar Controller (InfoBar.sh)
A toggle controller for your custom Quickshell workspace desktop bar.

Smart Toggling: Checks if the Quickshell InfoBar process is already active. If it is, it safely kills it; if it isn't, it fires it up.

Fallback Rendering: Forces the QT_QUICK_BACKEND=software rendering backend to ensure stability and cross-compatibility with various compositors and GPUs.

🚀 Quick Setup & Installation
You can pull the scripts, set up the required configurations, and install everything in one go. Run the following command in your terminal to create the directory structure and download the files into your local configurations.
