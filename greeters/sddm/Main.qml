// NIRUX SDDM greeter theme. Colours match the Niru Noir palette.
// Background and theme metadata are installed by the NIRUX installer.
import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: root
    width: 640
    height: 480
    color: "#0f0f10"

    readonly property color background: "#0f0f10"
    readonly property color surface: "#161618"
    readonly property color foreground: "#e5e5e5"
    readonly property color muted: "#a8a8a8"
    readonly property color border: "#2a2a2d"
    readonly property color accent: "#5a5a60"
    readonly property color error: "#d77a7a"

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        onLoginSucceeded: {
            message.text = textConstants.loginSucceeded
            message.color = accent
        }
        onLoginFailed: {
            password.text = ""
            message.text = textConstants.loginFailed
            message.color = error
        }
        onInformationMessage: {
            message.text = message
            message.color = error
        }
    }

    Background {
        anchors.fill: parent
        source: Qt.resolvedUrl(config.background)
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: "#990f0f10"
    }

    Rectangle {
        id: panel
        width: Math.min(root.width - 48, 420)
        height: content.implicitHeight + 56
        anchors.centerIn: parent
        color: "#e6161618"
        radius: 12
        border.color: root.border
        border.width: 1

        Column {
            id: content
            width: parent.width - 56
            anchors.centerIn: parent
            spacing: 10

            Text {
                width: parent.width
                text: "NIRUX"
                color: root.foreground
                font.pixelSize: 30
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                width: parent.width
                text: qsTr("A minimal X11 desktop")
                color: root.muted
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
            }
            Item { width: 1; height: 6 }

            Text {
                text: textConstants.userName
                color: root.muted
                font.pixelSize: 12
            }
            TextBox {
                id: name
                width: parent.width
                height: 34
                text: userModel.lastUser
                color: root.surface
                borderColor: root.border
                focusColor: root.accent
                hoverColor: root.accent
                textColor: root.foreground
                radius: 4
                font.pixelSize: 14
                KeyNavigation.tab: password
                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(name.text, password.text, session.index)
                        event.accepted = true
                    }
                }
            }

            Text {
                text: textConstants.password
                color: root.muted
                font.pixelSize: 12
            }
            PasswordBox {
                id: password
                width: parent.width
                height: 34
                color: root.surface
                borderColor: root.border
                focusColor: root.accent
                hoverColor: root.accent
                textColor: root.foreground
                radius: 4
                font.pixelSize: 14
                KeyNavigation.tab: session
                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(name.text, password.text, session.index)
                        event.accepted = true
                    }
                }
            }

            ComboBox {
                id: session
                width: parent.width
                height: 32
                model: sessionModel
                index: sessionModel.lastIndex
                color: root.surface
                borderColor: root.border
                focusColor: root.accent
                hoverColor: root.accent
                menuColor: root.surface
                textColor: root.foreground
                arrowColor: root.surface
                arrowIcon: Qt.resolvedUrl("arrow.png")
                font.pixelSize: 13
                KeyNavigation.tab: loginButton
            }

            Text {
                id: message
                width: parent.width
                text: textConstants.prompt
                color: root.muted
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width
                spacing: 8
                property int buttonWidth: (width - spacing * 2) / 3

                Button {
                    id: loginButton
                    width: parent.buttonWidth
                    text: textConstants.login
                    color: root.accent
                    activeColor: root.border
                    pressedColor: root.muted
                    textColor: root.foreground
                    borderColor: root.border
                    font.bold: true
                    onClicked: sddm.login(name.text, password.text, session.index)
                    KeyNavigation.tab: shutdownButton
                }
                Button {
                    id: shutdownButton
                    width: parent.buttonWidth
                    text: textConstants.shutdown
                    color: root.surface
                    activeColor: root.border
                    pressedColor: root.muted
                    textColor: root.foreground
                    borderColor: root.border
                    onClicked: sddm.powerOff()
                    KeyNavigation.tab: rebootButton
                }
                Button {
                    id: rebootButton
                    width: parent.buttonWidth
                    text: textConstants.reboot
                    color: root.surface
                    activeColor: root.border
                    pressedColor: root.muted
                    textColor: root.foreground
                    borderColor: root.border
                    onClicked: sddm.reboot()
                    KeyNavigation.tab: name
                }
            }
        }
    }

    Component.onCompleted: {
        if (name.text === "")
            name.focus = true
        else
            password.focus = true
    }
}
