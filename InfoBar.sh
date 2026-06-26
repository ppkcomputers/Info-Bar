#!/usr/bin/env bash
if pgrep -f "quickshell.*InfoBar/InfoBar.qml" >/dev/null; then
    pkill -f "quickshell.*InfoBar/InfoBar.qml"
else
    QT_QUICK_BACKEND=software quickshell -p ~/.config/quickshell/InfoBar/InfoBar.qml
fi
