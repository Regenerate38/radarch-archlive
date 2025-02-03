import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.0

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents

import "lib" as Lib
import "components" as Components
import "pages" as Pages
import "js/funcs.js" as Funcs 


Item {
    id: fullRep
    
    // PROPERTIES
    Layout.preferredWidth: root.fullRepWidth
    Layout.preferredHeight: wrapper.implicitHeight
    Layout.minimumWidth: Layout.preferredWidth
    Layout.maximumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight
    Layout.maximumHeight: Layout.preferredHeight
    clip: true

    property var layouts : [
        "layouts/Default.qml", 
        "layouts/ControlCenter.qml",
        "layouts/Flat.qml",
    ]
    
    // System session actions page
    Pages.SystemSessionActionsPage {
        id: systemSessionActionsPage
    }

    // Night Light Page
    Pages.NightLightPage {
        id: nightLightPage
    }

    // Volume devices Page
    Pages.VolumePage {
        id: volumePage
    }

    // Battery devices Page
    Pages.BatteryPage {
        id: batteryPage
    }

    // Media player Page
    Pages.MediaPlayerPage {
        id: mediaPlayerPage
    }

    // Brightness control Page
    Pages.BrightnessControlPage {
        id: brightnessControlPage
    }

    // Bluetooth control Page
    Pages.BluetoothPage {
        id: bluetoothPage
    }

    // Network control Page
    Pages.NetworkPage {
        id: networkPage
    }

    Loader {
        id: wrapper
        source: fullRep.layouts[plasmoid.configuration.layout]
        active: true
        asynchronous: true
        anchors.fill: parent
    }
}
