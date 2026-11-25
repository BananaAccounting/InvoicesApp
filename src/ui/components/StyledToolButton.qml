// Copyright [2021] [Banana.ch SA - Lugano Switzerland]
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "."

/**
 * A command of the toolbar: its icon and its name, side by side.
 *
 * The name is spelled out and not left to a tooltip, because this dialog has none - they
 * crashed the application as it closed and were taken out. An icon alone that is not
 * understood at first sight is never understood, and several of these commands are used
 * once a month: "Create invoice" and "New invoice" are a sentence apart, not a picture
 * apart. The label gives way only when the window is too narrow to hold it.
 *
 * Flat: a toolbar is a row of commands, not a row of boxes, so the frame appears under the
 * pointer instead of being painted all the time.
 */
Button {
    id: button

    /** Which icon to draw - see StyledIcon. */
    property string iconName: ""

    /** False leaves the icon on its own, where there is not enough room for the name. */
    property bool showLabel: true

    readonly property color contentColor: !button.enabled ? Stylesheet.mutedTextColor
                                                          : Stylesheet.textColor

    leftPadding: Stylesheet.spacingBase
    rightPadding: Stylesheet.spacingBase

    contentItem: RowLayout {
        spacing: Stylesheet.spacingTight + 2 * Stylesheet.pixelScaleRatio

        StyledIcon {
            name: button.iconName
            color: button.contentColor
            Layout.alignment: Qt.AlignVCenter
        }

        Label {
            visible: button.showLabel && button.text.length > 0
            text: button.text
            color: button.contentColor
            font: Stylesheet.labelFont
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
        }
    }

    background: Rectangle {
        implicitHeight: Stylesheet.controlHeight
        radius: Stylesheet.cornerRadius
        color: !button.enabled ? "transparent" :
                   button.pressed ? Stylesheet.pressedColor :
                       button.hovered ? Stylesheet.hoverColor : "transparent"

        Behavior on color {
            ColorAnimation { duration: 90 }
        }
    }
}
