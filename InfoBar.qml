import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    // ────────────────────────────────────────────────
    // Properties
    // ────────────────────────────────────────────────
    property string cpuUsage: "??%"
    property string ramUsage: "??%"
    property string diskSize: "??"
    property string diskUsed: "??"
    property string diskFree: "??"
    property string diskUsedPercent: "0"
    property string weatherInfo: "Loading weather..."

    property bool isVirtualMachine: false

    // Formatted multi-line string for all detected shares and statuses
    property string shareStatusDisplay: "Scanning network storage..."

    // ─── VM Detection ───────────────────────────────────
    Process {
        id: virtDetectProc
        command: ["sh", "-c", "systemd-detect-virt || virt-what || echo none"]
        stdout: SplitParser {
            onRead: (line) => {
                let output = line.trim().toLowerCase()
                isVirtualMachine = (output !== "none" && output !== "")
            }
        }
    }

    // ─── System Monitors ────────────────────────────────
    Process {
        id: cpuProc
        command: ["sh", "-c", "top -bn1 | grep '%Cpu(s)' | awk '{print $2 + $4}'"]
        stdout: SplitParser {
            onRead: (line) => {
                cpuUsage = parseFloat(line.trim()).toFixed(1) + "%"
            }
        }
    }

    Process {
        id: ramProc
        command: ["sh", "-c", "free -m | awk '/Mem:/ {printf \"%.0f%%\", $3/$2*100}'"]
        stdout: SplitParser {
            onRead: (line) => {
                ramUsage = line.trim()
            }
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", `
        if df / >/dev/null 2>&1; then
            df -h / | awk 'NR==2 {printf "%s|%s|%s|%s", $2, $3, $4, $5}'
            else
                echo "Error getting disk info"
                fi
                `]
                stdout: SplitParser {
                    onRead: (line) => {
                        let trimmed = line.trim()
                        if (trimmed.includes("|")) {
                            let parts = trimmed.split("|")
                            if (parts.length >= 4) {
                                diskSize = parts[0]
                                diskUsed = parts[1]
                                diskFree = parts[2]
                                diskUsedPercent = parts[3].replace("%", "").trim()
                            }
                        }
                    }
                }
    }

    Process {
        id: weatherProc
        command: ["sh", "-c", `
        WEATHER=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=-33.78&longitude=20.12&current_weather=true&hourly=precipitation_probability")
        TEMP=$(echo "$WEATHER" | jq '.current_weather.temperature')
        RAIN=$(echo "$WEATHER" | jq '.hourly.precipitation_probability[0]')
        echo "Montagu: $TEMP°C | Rain Chance: $RAIN%"
        `]
        stdout: SplitParser {
            onRead: (line) => {
                weatherInfo = line.trim()
            }
        }
    }

    // ─── Dynamic Shared Folders Discovery & Audit Engine ───
    Process {
        id: sharedFoldersProc
        command: ["sh", "-c", `
        # 1. Dynamically find all cifs, nfs, smb3 mounts, or any custom mounts stashed inside /mnt
        SHARES=$(findmnt -V >/dev/null 2>&1 && findmnt -lo TARGET,FSTYPE | awk '$2~/cifs|nfs|smb3/ {print $1}' || awk '$2~/\\/mnt/ {print $1}' /proc/mounts)

        if [ -z "$SHARES" ]; then
            echo "No active network shares mapped."
            exit 0
            fi

            OUTPUT=""
            # 2. Iterate through every single discovered share path
            for share in $SHARES; do
                bname=$(basename "$share")

                # 3. Apply the non-cached df test on the discovered path
                if timeout 1 df "$share" >/dev/null 2>&1; then
                    STATUS="ONLINE"
                    else
                        STATUS="OFFLINE"
                        fi

                        # Format output line by line: "Folder: STATUS"
                        if [ -z "$OUTPUT" ]; then
                            OUTPUT="\${bname}: \${STATUS}"
                            else
                                OUTPUT="\${OUTPUT}\n\${bname}: \${STATUS}"
                                fi
                                done

                                echo -e "$OUTPUT"
                                `]
                                stdout: SplitParser {
                                    splitMarker: "\n"
                                    onRead: (line) => {
                                        if (sharedFoldersProc.lineCount === 0) {
                                            shareStatusDisplay = ""
                                        }

                                        let cleanLine = line.trim()
                                        if (cleanLine !== "") {
                                            if (shareStatusDisplay === "") {
                                                shareStatusDisplay = cleanLine
                                            } else {
                                                shareStatusDisplay += "\n" + cleanLine
                                            }
                                        }
                                        sharedFoldersProc.lineCount++
                                    }
                                }
                                property int lineCount: 0
    }

    // ─── Lifecycle & Timers ─────────────────────────────
    Component.onCompleted: {
        virtDetectProc.running = true
        weatherProc.running = true
        diskProc.running = true

        sharedFoldersProc.lineCount = 0
        sharedFoldersProc.running = true
    }

    Timer {
        id: globalUpdateTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = false; cpuProc.running = true
            ramProc.running = false; ramProc.running = true
            diskProc.running = false; diskProc.running = true
            weatherProc.running = false; weatherProc.running = true

            sharedFoldersProc.lineCount = 0
            sharedFoldersProc.running = false; sharedFoldersProc.running = true
        }
    }

    // ─── The UI Window ──────────────────────────────────
    PanelWindow {
        id: window
        anchors { top: true; bottom: true; right: true }
        implicitWidth: 380
        visible: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0

        onVisibleChanged: {
            if (visible) {
                sharedFoldersProc.lineCount = 0
                sharedFoldersProc.running = false
                sharedFoldersProc.running = true
            }
        }

        Rectangle {
            id: body
            x: window.implicitWidth
            width: 320
            height: parent.height
            color: Qt.rgba(0.06, 0.07, 0.08, 0.96)
            border.color: "#b0ac63"
            border.width: 1
            radius: 16

            Behavior on x {
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
            }

            Column {
                anchors {
                    fill: parent
                    topMargin: 0
                    bottomMargin: 0
                }
                spacing: 0

                // Heading Section
                Rectangle {
                    width: parent.width
                    height: childrenRect.height + 40
                    color: Qt.rgba(0.69, 0.675, 0.388, 0.18)

                    Column {
                        anchors {
                            top: parent.top
                            topMargin: 28
                            horizontalCenter: parent.horizontalCenter
                        }
                        spacing: 20
                        width: parent.width - 48

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "System Info"
                            color: "#b0ac63"
                            font.pixelSize: 30
                            font.family: "Monospace"
                            font.bold: true
                            font.letterSpacing: 1.5
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#b0ac63"
                            opacity: 0.3
                        }
                    }
                }

                // Clock Section
                Rectangle {
                    width: parent.width
                    height: childrenRect.height + 40
                    color: Qt.rgba(0.22, 0.243, 0.208, 0.22)

                    Column {
                        anchors {
                            top: parent.top
                            topMargin: 24
                            horizontalCenter: parent.horizontalCenter
                        }
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
                            color: "#b0ac63"
                            font.pixelSize: 54
                            font.family: "Monospace"
                            font.weight: Font.Bold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: new Date().toLocaleDateString(Qt.locale(), "dddd dd MMMM")
                            color: "#b0ac63"
                            font.pixelSize: 19
                            font.family: "Monospace"
                            opacity: 0.9
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#b0ac63"
                    opacity: 0.25
                }

                // Stats Section (CPU + RAM)
                Rectangle {
                    width: parent.width
                    height: childrenRect.height + 50
                    color: Qt.rgba(0.69, 0.675, 0.388, 0.14)

                    Column {
                        anchors {
                            top: parent.top
                            topMargin: 24
                            horizontalCenter: parent.horizontalCenter
                        }
                        spacing: 20
                        width: parent.width - 48

                        Row {
                            spacing: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            Text { text: "CPU";  color: "#b0ac63"; font.pixelSize: 18; font.family: "Monospace"; opacity: 0.9 }
                            Text { text: cpuUsage; color: "#b0ac63"; font.pixelSize: 18; font.family: "Monospace"; font.bold: true }
                        }

                        Row {
                            spacing: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            Text { text: "RAM";  color: "#b0ac63"; font.pixelSize: 18; font.family: "Monospace"; opacity: 0.9 }
                            Text { text: ramUsage; color: "#b0ac63"; font.pixelSize: 18; font.family: "Monospace"; font.bold: true }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#b0ac63"
                    opacity: 0.25
                }

                // Disk Section
                Rectangle {
                    width: parent.width
                    height: childrenRect.height + 50
                    color: Qt.rgba(0.58, 0.60, 0.45, 0.32)

                    Column {
                        anchors {
                            top: parent.top
                            topMargin: 24
                            horizontalCenter: parent.horizontalCenter
                        }
                        spacing: 14
                        width: parent.width - 48

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Disk"
                            color: "#b0ac63"
                            font.pixelSize: 20
                            font.family: "Monospace"
                            font.bold: true
                        }

                        Row {
                            width: parent.width
                            spacing: 12
                            Text { text: "Size:"; color: "#b0ac63"; font.pixelSize: 17; font.family: "Monospace"; width: 72 }
                            Text { text: diskSize; color: "#b0ac63"; font.pixelSize: 17; font.family: "Monospace"; font.bold: true }
                        }

                        Row {
                            width: parent.width
                            spacing: 12
                            Text { text: "Used:"; color: "#b0ac63"; font.pixelSize: 17; font.family: "Monospace"; width: 72 }
                            Text { text: diskUsed; color: "#b0ac63"; font.pixelSize: 17; font.family: "Monospace"; font.bold: true }
                        }

                        Row {
                            width: parent.width
                            spacing: 12
                            Text { text: "Free:"; color: "#b0ac63"; font.pixelSize: 17; font.family: "Monospace"; width: 72 }
                            Text { text: diskFree; color: "#b0ac63"; font.pixelSize: 17; font.family: "Monospace"; font.bold: true }
                        }

                        Row {
                            width: parent.width
                            spacing: 12
                            Text { text: "Used:"; color: "#b0ac63"; font.pixelSize: 17; font.family: "Monospace"; width: 72 }
                            Text { text: diskUsedPercent + "%"; color: "#b0ac63"; font.pixelSize: 17; font.family: "Monospace"; font.bold: true }
                        }

                        Row {
                            width: parent.width
                            spacing: 4
                            Repeater {
                                model: 10
                                Rectangle {
                                    width: (parent.width - 36) / 10
                                    height: 18
                                    color: {
                                        let pct = parseFloat(diskUsedPercent)
                                        let step = Math.round(pct / 10)
                                        return (index < step) ? "#b0ac63" : Qt.rgba(0.2, 0.2, 0.2, 0.9)
                                    }
                                    radius: 4
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#b0ac63"
                    opacity: 0.25
                }

                // Weather Section
                Rectangle {
                    width: parent.width
                    height: childrenRect.height + 50
                    color: Qt.rgba(0.22, 0.243, 0.208, 0.22)

                    Column {
                        anchors {
                            top: parent.top
                            topMargin: 24
                            horizontalCenter: parent.horizontalCenter
                        }
                        spacing: 12
                        width: parent.width - 48

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Weather"
                            color: "#b0ac63"
                            font.pixelSize: 20
                            font.family: "Monospace"
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: weatherInfo
                            color: "#b0ac63"
                            font.pixelSize: 17
                            font.family: "Monospace"
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#b0ac63"
                    opacity: 0.25
                }

                // Shared Folders & Remount Section
                Rectangle {
                    width: parent.width
                    height: childrenRect.height + 30
                    color: Qt.rgba(0.15, 0.16, 0.18, 0.4)

                    Column {
                        anchors {
                            top: parent.top
                            topMargin: 20
                            horizontalCenter: parent.horizontalCenter
                        }
                        spacing: 16
                        width: parent.width - 48

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Shared Folders"
                            color: "#b0ac63"
                            font.pixelSize: 20
                            font.family: "Monospace"
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: shareStatusDisplay
                            color: "#b0ac63"
                            font.pixelSize: 15
                            font.family: "Monospace"
                            lineHeight: 1.3
                            wrapMode: Text.WordWrap
                        }

                        // ─── Remount Notice Container ───
                        Column {
                            width: parent.width
                            spacing: 6
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Remount shared folders"
                                color: "#b0ac63"
                                font.pixelSize: 13
                                font.family: "Monospace"

                            }

                            Rectangle {
                                width: parent.width - 30
                                height: childrenRect.height + 12
                                color: Qt.rgba(0, 0, 0, 0.3)
                                radius: 6
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "sudo mount -a"
                                    color: "#b0ac63"
                                    font.pixelSize: 13
                                    font.family: "Monospace"
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }

        // Slide-in animation
        Timer {
            interval: 100
            running: true
            onTriggered: body.x = 50
        }
    }
}
