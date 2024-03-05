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

Dialog {
    id: popup
    property alias text: label.text;

    background: Rectangle {
      // implicitWidth: contentItem.Width
      radius: 2.0 * Stylesheet.pixelScaleRatio
      border.color: "#bdbebf"
    }

    width: 300 * Stylesheet.pixelScaleRatio
    height: 50 * Stylesheet.pixelScaleRatio

    x: (parent.width - width) / 2
    y: 0

    contentItem: Text {
        id: label
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        MouseArea {
            anchors.fill: label
            onClicked: {
                popup.close()
            }
        }
    }

    standardButtons: Dialog.NoButton

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 0.7 }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 0.7; to: 0.0 }
    }

    Timer {
        id: timer
        interval: 5000 // milliseconds
        running: true
        repeat: false
        onTriggered: {
            popup.close()
        }
    }

    onOpened: {
        timer.start()
    }
}
