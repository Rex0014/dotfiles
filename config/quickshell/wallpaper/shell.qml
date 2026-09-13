pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property int thumbHeight: 160
    readonly property int thumbWidth: 280
    readonly property real centerScale: 1.35

    property string wallsDir: `${Quickshell.env("HOME")}/Pictures/Wallpapers`
    property string currentWallpaper: ""
    property bool shown: false

    function refreshWallsDir(): void {
        const envDir = Quickshell.env("CAELESTIA_WALLPAPERS_DIR");
        let dir = envDir;
        if (!dir) {
            try {
                dir = JSON.parse(configFile.text())?.paths?.wallpaperDir;
            } catch (e) {
                dir = "";
            }
        }
        if (!dir)
            dir = "~/Pictures/Wallpapers";
        root.wallsDir = dir.replace(/^~/, Quickshell.env("HOME"));
        runScan();
    }

    function runScan(): void {
        scanProc.running = false;
        scanProc.running = true;
    }

    function findIndexForPath(path: string): int {
        for (let i = 0; i < wallModel.count; i++) {
            if (wallModel.get(i).path === path)
                return i;
        }
        return -1;
    }

    function openPicker(): void {
        if (wallModel.count === 0)
            return;

        runScan();
        const idx = findIndexForPath(currentWallpaper);
        listView.currentIndex = idx >= 0 ? idx : 0;
        shown = true;
        idleTimer.restart();
    }

    function closePicker(): void {
        idleTimer.stop();
        shown = false;
    }

    function toggle(): void {
        if (shown)
            closePicker();
        else
            openPicker();
    }

    function nudge(dir: int): void {
        if (!shown || wallModel.count === 0)
            return;

        listView.currentIndex = Math.max(0, Math.min(wallModel.count - 1, listView.currentIndex + dir));

        idleTimer.restart();
        applyTimer.restart();
    }

    FileView {
        id: configFile

        path: `${Quickshell.env("HOME")}/.config/caelestia/shell.json`
        watchChanges: true
        printErrors: false
        onLoaded: root.refreshWallsDir()
        onLoadFailed: root.refreshWallsDir()
        onFileChanged: reload()
    }

    FileView {
        id: currentWallpaperFile

        path: `${Quickshell.env("HOME")}/.local/state/caelestia/wallpaper/path.txt`
        watchChanges: true
        printErrors: false
        onLoaded: root.currentWallpaper = text().trim()
        onFileChanged: reload()
    }

    ListModel {
        id: wallModel
    }

    Process {
        id: scanProc

        command: ["find", root.wallsDir, "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", "-o", "-iname", "*.gif", "-o", "-iname", "*.bmp", ")"]

        stdout: StdioCollector {
            onStreamFinished: {
                const paths = text.trim().split("\n").filter(p => p.length > 0).sort();
                const previousPath = wallModel.count > 0 && listView.currentIndex >= 0 ? wallModel.get(listView.currentIndex).path : "";

                wallModel.clear();
                for (const p of paths)
                    wallModel.append({
                        path: p
                    });

                if (previousPath) {
                    const idx = root.findIndexForPath(previousPath);
                    if (idx >= 0)
                        listView.currentIndex = idx;
                }
            }
        }
    }

    Timer {
        id: applyTimer

        interval: 300
        onTriggered: {
            if (listView.currentIndex >= 0 && listView.currentIndex < wallModel.count) {
                const path = wallModel.get(listView.currentIndex).path;
                root.currentWallpaper = path;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", path]);
            }
        }
    }

    Timer {
        id: idleTimer

        interval: 2500
        onTriggered: root.shown = false
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            root.toggle();
        }

        function left(): void {
            root.nudge(-1);
        }

        function right(): void {
            root.nudge(1);
        }
    }

    PanelWindow {
        id: win

        visible: root.shown
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "wallpaper-picker"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                idleTimer.stop();
                root.shown = false;
            }
        }

        ListView {
            id: listView

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: root.thumbHeight * root.centerScale + 40
            clip: true

            orientation: ListView.Horizontal
            interactive: false
            spacing: 24

            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - root.thumbWidth / 2
            preferredHighlightEnd: width / 2 + root.thumbWidth / 2
            highlightMoveDuration: 220

            model: wallModel

            header: Item {
                width: Math.max(0, listView.width / 2 - root.thumbWidth / 2)
                height: 1
            }
            footer: Item {
                width: Math.max(0, listView.width / 2 - root.thumbWidth / 2)
                height: 1
            }

            delegate: Item {
                id: delegateRoot

                required property string path

                width: root.thumbWidth
                height: root.thumbHeight

                scale: ListView.isCurrentItem ? root.centerScale : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: root.thumbWidth
                    height: root.thumbHeight
                    radius: 14
                    clip: true
                    color: "#222222"

                    Image {
                        anchors.fill: parent
                        source: `file://${delegateRoot.path}`
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }
        }
    }
}
