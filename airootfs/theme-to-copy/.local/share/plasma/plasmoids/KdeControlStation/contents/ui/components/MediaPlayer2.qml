import QtQuick 2.15
import QtQuick.Layouts 1.15
//import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects

import org.kde.plasma.private.mediacontroller 1.0
import org.kde.plasma.private.mpris as Mpris

import org.kde.coreaddons 1.0 as KCoreAddons


import "../lib" as Lib

Lib.Card {
    id: mediaPlayer2
    visible: root.showMediaPlayer
    Layout.fillWidth: true
    Layout.preferredHeight: root.sectionHeight/2
  //  anchors.margins: 0

     // readonly property alias playerSelector: playerSelector
    readonly property int controlSize: Kirigami.Units.iconSizes.medium

    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    property real rate: mediaPlayerPage.mpris2Model.currentPlayer?.rate ?? 1
    property double length: mediaPlayerPage.mpris2Model.currentPlayer?.length ?? 0
    property double position: mediaPlayerPage.mpris2Model.currentPlayer?.position ?? 0
    property bool canSeek: mediaPlayerPage.mpris2Model.currentPlayer?.canSeek ?? false

    // only show hours (the default for KFormat) when track is actually longer than an hour
    readonly property int durationFormattingOptions: length >= 60*60*1000*1000 ? 0 : KCoreAddons.FormatTypes.FoldHours

    property bool disablePositionUpdate: false
    property bool keyPressed: false

    onPositionChanged: {
        // we don't want to interrupt the user dragging the slider
        if (!seekSlider.pressed && !keyPressed) {
            // we also don't want passive position updates
            disablePositionUpdate = true
            // Slider refuses to set value beyond its end, make sure "to" is up-to-date first
            seekSlider.to = length;
            seekSlider.value = position
            disablePositionUpdate = false
        }
    }

    onLengthChanged: {
        disablePositionUpdate = true
        // When reducing maximumValue, value is clamped to it, however
        // when increasing it again it gets its old value back.
        // To keep us from seeking to the end of the track when moving
        // to a new track, we'll reset the value to zero and ask for the position again
        seekSlider.value = 0
        seekSlider.to = length
        mediaPlayerPage.mpris2Model.currentPlayer?.updatePosition();
        disablePositionUpdate = false
    }

    Timer {
        id: queuedPositionUpdate
        interval: 100
        onTriggered: {
            if (mediaPlayer2.position == seekSlider.value) {
                return;
            }
            mediaPlayerPage.mpris2Model.currentPlayer.position = seekSlider.value;
        }
    }

    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            mediaPlayerPage.toggleSection()
        }
    }

    // Image {
    //     id: audioThumb
    //     fillMode: Image.PreserveAspectCrop
    //     source: mediaPlayerPage.albumArt || "../../assets/music.svg"
    //    anchors.fill: parent
    //     enabled: mediaPlayerPage.track || (mediaPlayerPage.playbackStatus > Mpris.PlaybackStatus.Stopped) ? true : false
    //     z: -1
    //     ColorOverlay {
    //         visible: !mediaPlayerPage.albumArt && audioThumb.enabled
    //         anchors.fill: audioThumb
    //         source: audioThumb
    //         color: Kirigami.Theme.textColor
    //     }
    // }

    RowLayout {
       Layout.fillWidth:true
       // anchors.margins: root.smallSpacing

        Image {
            id: audioThumb
            fillMode: Image.PreserveAspectCrop
            source: mediaPlayerPage.albumArt || "../../assets/music.svg"
            Layout.fillHeight: true
            Layout.preferredWidth: height
            enabled: mediaPlayerPage.track || (mediaPlayerPage.playbackStatus > Mpris.PlaybackStatus.Stopped) ? true : false

            ColorOverlay {
                visible: !mediaPlayerPage.albumArt && audioThumb.enabled
                anchors.fill: audioThumb
                source: audioThumb
                color: Kirigami.Theme.textColor
            }
        }
        ColumnLayout {
            id: mediaNameWrapper
            Layout.margins: root.smallSpacing
            // Layout.fillHeight: true
            Layout.preferredWidth: (root.fullRepWidth / 3) * 2
            spacing: 0

            PlasmaComponents.Label {
                id: audioTitle
              //  Layout.fillWidth: true
                font.capitalization: Font.Capitalize
                font.weight: Font.Bold
                font.pixelSize: root.largeFontSize
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
              // anchors.top: parent.top
                enabled: mediaPlayerPage.track || (mediaPlayerPage.playbackStatus > Mpris.PlaybackStatus.Stopped) ? true : false
                //horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: mediaPlayerPage.track ? mediaPlayerPage.track : (mediaPlayerPage.playbackStatus > Mpris.PlaybackStatus.Stopped) ? i18n("No title") : i18n("No media playing")
            }
            PlasmaComponents.Label {
                id: audioArtist
                Layout.fillWidth: true
                font.pixelSize: root.mediumFontSize
               // horizontalAlignment: Text.AlignHCenter
                text: mediaPlayerPage.artist
            }

            PlasmaComponents.Slider { // Slider
                    id: seekSlider
                    Layout.fillWidth: true
                    z: 999
                    value: 0
                    visible: canSeek

                    // KeyNavigation.backtab: playerSelector.currentItem
                    KeyNavigation.up: KeyNavigation.backtab
                    KeyNavigation.down: playPauseButton.enabled ? playPauseButton : (playPauseButton.KeyNavigation.left.enabled ? playPauseButton.KeyNavigation.left : playPauseButton.KeyNavigation.right)
                    Keys.onLeftPressed: {
                        seekSlider.value = Math.max(0, seekSlider.value - 5000000) // microseconds
                        seekSlider.moved();
                    }
                    Keys.onRightPressed: {
                        seekSlider.value = Math.max(0, seekSlider.value + 5000000) // microseconds
                        seekSlider.moved();
                    }

                    onMoved: {
                        if (!disablePositionUpdate) {
                            // delay setting the position to avoid race conditions
                            queuedPositionUpdate.restart()
                        }
                    }
                    onPressedChanged: {
                        // Property binding evaluation is non-deterministic
                        // so binding visible to pressed and delay to 0 when pressed
                        // will not make the tooltip show up immediately.
                        if (pressed) {
                            seekToolTip.delay = 0;
                            seekToolTip.visible = true;
                        } else {
                            seekToolTip.delay = Qt.binding(() => Kirigami.Units.toolTipDelay);
                            seekToolTip.visible = Qt.binding(() => seekToolTipHandler.hovered);
                        }
                    }

                    HoverHandler {
                        id: seekToolTipHandler
                    }

                    PlasmaComponents.ToolTip {
                        id: seekToolTip
                        readonly property real position: {
                            if (seekSlider.pressed) {
                                return seekSlider.visualPosition;
                            }
                            // does not need mirroring since we work on raw mouse coordinates
                            const mousePos = seekToolTipHandler.point.position.x - seekSlider.handle.width / 2;
                            return Math.max(0, Math.min(1, mousePos / (seekSlider.width - seekSlider.handle.width)));
                        }
                        x: Math.round(seekSlider.handle.width / 2 + position * (seekSlider.width - seekSlider.handle.width) - width / 2)
                        // Never hide (not on press, no timeout) as long as the mouse is hovered
                        closePolicy: PlasmaComponents.Popup.NoAutoClose
                        timeout: -1
                        text: {
                            // Label text needs mirrored position again
                            const effectivePosition = seekSlider.mirrored ? (1 - position) : position;
                            return KCoreAddons.Format.formatDuration((seekSlider.to - seekSlider.from) * effectivePosition / 1000, mediaPlayer2.durationFormattingOptions)
                        }
                        // NOTE also controlled in onPressedChanged handler above
                        visible: seekToolTipHandler.hovered
                    }

                    Timer {
                        id: seekTimer
                        interval: 1000 / mediaPlayer2.rate
                        repeat: true
                        running: mediaPlayerPage.isPlaying && !keyPressed && interval > 0 && seekSlider.to >= 1000000
                        onTriggered: {
                            // some players don't continuously update the seek slider position via mpris
                            // add one second; value in microseconds
                            if (!seekSlider.pressed) {
                                disablePositionUpdate = true
                                if (seekSlider.value == seekSlider.to) {
                                    mpris2Model.currentPlayer.updatePosition();
                                } else {
                                    seekSlider.value += 1000000
                                }
                                disablePositionUpdate = false
                            }
                        }
                    }
                }

            RowLayout { // Seek Bar
                //spacing: Kirigami.Units.smallSpacing

                // if there's no "mpris:length" in the metadata, we cannot seek, so hide it in that case
                enabled: mediaPlayerPage.playerList.count > 0 && mediaPlayerPage.track.length > 0 && mediaPlayer2.length > 0 ? true : false
                opacity: enabled ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Kirigami.Units.longDuration }
                }
                // Layout.topMargin: root.smallSpacing
                // Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.fillWidth: true
                //Layout.maximumWidth: Math.min(Kirigami.Units.gridUnit * 45, Math.round(mediaPlayer2.width * (7 / 10)))

                // ensure the layout doesn't shift as the numbers change and measure roughly the longest text that could occur with the current song
                TextMetrics {
                    id: timeMetrics
                    text: i18nc("Remaining time for song e.g -5:42", "-%1",
                                KCoreAddons.Format.formatDuration(seekSlider.to / 1000, mediaPlayer2.durationFormattingOptions))
                    font: Kirigami.Theme.smallFont
                }

                PlasmaComponents.Label { // Time Elapsed
                    Layout.preferredWidth: timeMetrics.width
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: KCoreAddons.Format.formatDuration(seekSlider.value / 1000, mediaPlayer2.durationFormattingOptions)
                    opacity: 0.9
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.textColor
                    textFormat: Text.PlainText
                }
                Item {
                    Layout.fillWidth: true
                }


                RowLayout {
                    visible: !canSeek

                    Layout.fillWidth: true
                    Layout.preferredHeight: seekSlider.height

                    PlasmaComponents.ProgressBar { // Time Remaining
                        value: seekSlider.value
                        from: seekSlider.from
                        to: seekSlider.to

                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                PlasmaComponents.Label {
                    Layout.preferredWidth: timeMetrics.width
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: i18nc("Remaining time for song e.g -5:42", "-%1",
                                KCoreAddons.Format.formatDuration((seekSlider.to - seekSlider.value) / 1000, mediaPlayer2.durationFormattingOptions))
                    opacity: 0.9
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.textColor
                    textFormat: Text.PlainText
                }
            }

        }
        RowLayout {
            id: audioControls
            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: false

            PlasmaComponents.ToolButton {
                id: previousButton
                Layout.preferredHeight: mediaNameWrapper.implicitHeight
                Layout.preferredWidth: height
                icon.name: "media-skip-backward"
                enabled: mediaPlayerPage.canGoPrevious
                onClicked: {
                    //seekSlider.value = 0    // Let the media start from beginning. Bug 362473
                    mediaPlayerPage.previous()
                }
            }

            PlasmaComponents.ToolButton { // Pause/Play
                id: playPauseButton

                Layout.preferredHeight: mediaNameWrapper.implicitHeight
                Layout.preferredWidth: height

                Layout.alignment: Qt.AlignVCenter
                enabled: mediaPlayerPage.isPlaying ? mediaPlayerPage.canPause : mediaPlayerPage.canPlay
                icon.name: mediaPlayerPage.isPlaying ? "media-playback-pause" : "media-playback-start"

                onClicked: mediaPlayerPage.togglePlaying()
            }


            PlasmaComponents.ToolButton {
                id: nextButton
                Layout.preferredHeight: mediaNameWrapper.implicitHeight
                Layout.preferredWidth: height
                icon.name: "media-skip-forward"
                enabled: mediaPlayerPage.canGoNext
                onClicked: {
                    //seekSlider.value = 0    // Let the media start from beginning. Bug 362473
                    mediaPlayerPage.next()
                }
            }
        }
    }


}
