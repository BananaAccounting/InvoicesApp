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

ComboBox {
    id: control

    implicitHeight: 28 * Stylesheet.pixelScaleRatio
    indicator.width: 20 * Stylesheet.pixelScaleRatio
    indicator.height: 20 * Stylesheet.pixelScaleRatio

    // Popup minimun widht (popup can be larger than the control
    property int popupMinWidth: 0

    // Popup alignment, to the left or right to the control
    property int popupAlign: Qt.AlignLeft

    background: Rectangle {
        color: Stylesheet.baseColor
        border.width: 1
        border.color: "#bdbebf"
        radius: 2.0 * Stylesheet.pixelScaleRatio
    }

    popup: Popup {
        x: popupAlign === Qt.AlignRight ? (width > control.width ? control.width - width : 0) : 0
        y: control.height - 1 * Stylesheet.pixelScaleRatio
        width: !control.model || control.model.count === 0 ? 0 : Math.max(control.width, popupMinWidth)
        padding: 1 * Stylesheet.pixelScaleRatio
        property var listView: listView

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: Math.min(200 * Stylesheet.pixelScaleRatio, contentHeight)
            model: control.popup.visible ? control.delegateModel : null
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: Stylesheet.baseColor
            border.color: "#354793"
            radius: 2 * Stylesheet.pixelScaleRatio
        }
    }

}
