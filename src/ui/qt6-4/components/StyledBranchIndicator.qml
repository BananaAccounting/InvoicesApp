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
import QtQuick.Shapes

Shape {
    id: shape

    property bool expanded: false

    width: 12 * Stylesheet.pixelScaleRatio
    height: 12 * Stylesheet.pixelScaleRatio

    ShapePath {
        strokeWidth: 1
        strokeColor: Stylesheet.textColor
        fillColor: Stylesheet.textColor
        fillRule: Qt.WindingFill
        startX: 0; startY: 0
        PathLine { x: shape.width / 2; y: shape.height / 2 }
        PathLine { x: 0; y: shape.height }
        PathLine { x: 0; y: 0 }
    }

    state: expanded ? "expanded" : ""

    states: State {
        name: "expanded"
        PropertyChanges {
            target: shape;
            rotation: 90
            y: 12 / 2
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {expanded = !expanded}
    }

}
