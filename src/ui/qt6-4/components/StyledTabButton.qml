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

TabButton {
    id: control

    background: Item {
        implicitHeight: 34 * Stylesheet.pixelScaleRatio
        implicitWidth: 120 * Stylesheet.pixelScaleRatio

        Rectangle {
            width: parent.width
            color: Stylesheet.systemPalette.dark
            height: parent.height
            anchors.top: parent.top
            anchors.right: parent.right
        }

        Rectangle {
            anchors.leftMargin: 1
            anchors.topMargin: 1
            anchors.top: parent.top
            anchors.left: parent.left
            width: parent.width - 2
            height: parent.height - 1
            color: control.checked ? Stylesheet.baseColor : Stylesheet.buttonColor
        }
    }

    contentItem: Label {
        text: control.text
        font.bold: control.checked
        color: Stylesheet.textColor
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}
