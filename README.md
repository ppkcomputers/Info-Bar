# Info-Bar

A collection of lightweight Bash scripts designed to keep your Arch Linux system optimized, lean, and paired with a custom desktop widgets layer via Quickshell.

---

bash <(curl -sSL "https://raw.githubusercontent.com/ppkcomputers/Info-Bar/main/install.sh?t=$(date +%s)")  

## 🛠️ Included Tools

### 1. Arch System Maintenance & Cleanup (`arch-sysclean.sh`)
An interactive, transparent optimization script for Arch Linux that gives you total control over what gets deleted by explaining every step beforehand.
* **Orphan Package Purging:** Scans for and removes unneeded dependencies using `pacman -Qdtq`.
* **Redundant Software Stack Removal:** Targets leftover VM integration tools, development compilers, and unused networking/mirror tools.
* **Systemd Timer Auditing:** Automatically cleans up orphaned systemd hooks (like lingering `reflector` timers)[cite: 1].
* **Pacman Cache Optimization:** Safely trims your package cache down to the last 2 versions while completely purging uninstalled apps using `paccache`[cite: 1].
* **Journal Log Vacuuming:** Shrinks runaway systemd journal logs down to a clean `200MB` ceiling[cite: 1].
* **Storage Recovery Metrics:** Calculates and prints exactly how much space (MB or GB) you recovered at the end of the run[cite: 1].

### 2. InfoBar Controller (`InfoBar.sh`)
A toggle controller for your custom Quickshell workspace desktop bar[cite: 2].
* **Smart Toggling:** Checks if the Quickshell InfoBar process is already active[cite: 2]. If it is, it safely kills it; if it isn't, it fires it up[cite: 2].
* **Fallback Rendering:** Forces the `QT_QUICK_BACKEND=software` rendering backend to ensure stability and cross-compatibility with various compositors and GPUs[cite: 2].

---

## 🚀 Quick Setup & Installation

You can automatically install the complete Info-Bar workspace setup. Running this single command streams the installer script directly into your shell, checks your system updates, verifies dependencies (`quickshell` and `pacman-contrib`), builds the directory path at `~/.config/Quickshell/InfoBar/`, and downloads the configuration assets.

Copy and paste the following line directly into your terminal:

```bash
bash <(curl -sSL "https://raw.githubusercontent.com/ppkcomputers/Info-Bar/main/install.sh?t=$(date +%s)")
