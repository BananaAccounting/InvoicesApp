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

    hoverEnabled: true

    background: Item {
        implicitHeight: 34 * Stylesheet.pixelScaleRatio
        implicitWidth: 120 * Stylesheet.pixelScaleRatio

        Rectangle {
            anchors.fill: parent
            color: control.checked ? Stylesheet.baseColor :
                       control.hovered ? Stylesheet.hoverColor : Stylesheet.buttonColor
        }

        Rectangle {
            // Active-tab indicator, in the banana blue accent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 3 * Stylesheet.pixelScaleRatio
            color: Stylesheet.accentColor
            visible: control.checked
        }
    }

    contentItem: Label {
        text: control.text
        font.bold: control.checked
        color: control.checked ? Stylesheet.textColor : Stylesheet.mutedTextColor
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}
