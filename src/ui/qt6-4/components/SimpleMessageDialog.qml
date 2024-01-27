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
This dialog replace the component MessageDialog.
The MessageDialog is crashing application compiled and run with webassembly.
*/

Dialog {
    property alias text: label.text;

    x: (parent.width - width) / 2
    y: 0
    width: 400 * Stylesheet.pixelScaleRatio
    height: 200 * Stylesheet.pixelScaleRatio

    background: Rectangle {
      // implicitWidth: contentItem.Width
      color: Stylesheet.baseColor
      radius: 2.0 * Stylesheet.pixelScaleRatio
      border.color: "#bdbebf"
    }

    Text {
        id: label
        wrapMode: Text.Wrap
        color: Stylesheet.textColor
    }

    footer: DialogButtonBox {
        delegate: StyledButton {}
        background: Rectangle {
          x: 1
          y: 1
          color: Stylesheet.baseColor
        }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
    }

    standardButtons: Dialog.Ok
}
