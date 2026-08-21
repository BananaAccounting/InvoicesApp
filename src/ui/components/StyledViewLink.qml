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

import "."

/**
 * A single option of a pill-style view switcher (see the "Views:" selector
 * in WdgInvoice.qml). Gives a clearer clickable affordance than plain
 * underlined text: a rounded background that highlights the selected view
 * and reacts on hover.
 */
Rectangle {
    id: root

    property alias text: label.text
    property bool selected: false

    signal clicked()

    implicitHeight: 26 * Stylesheet.pixelScaleRatio
    implicitWidth: label.implicitWidth + 2 * Stylesheet.defaultMargin
    radius: height / 2

    color: selected ? Stylesheet.accentColor :
                       (hoverArea.containsMouse ? Stylesheet.hoverColor : "transparent")

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    StyledLabel {
        id: label
        anchors.centerIn: parent
        font.bold: root.selected
        color: root.selected ? Stylesheet.accentTextColor : Stylesheet.textColor
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.selected ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
