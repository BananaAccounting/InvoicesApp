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

Switch {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    indicator: Rectangle {
        implicitWidth: 40 * Stylesheet.pixelScaleRatio
        implicitHeight: 20 * Stylesheet.pixelScaleRatio

        x: control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2

        color: control.checked ? Stylesheet.accentColor : Stylesheet.hoverColor
        border.color: control.checked ? Stylesheet.accentColor : Stylesheet.borderColorStrong
        border.width: control.visualFocus ? 2 : 1
        radius: height / 2

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Rectangle {
            x: Math.max(2, Math.min(parent.width - width - 2, control.visualPosition * parent.width - (width / 2)))
            y: (parent.height - height) / 2
            width: 16 * Stylesheet.pixelScaleRatio
            height: 16 * Stylesheet.pixelScaleRatio
            color: "white"
            radius: height / 2

            Behavior on x {
                enabled: !control.down
                SmoothedAnimation { velocity: 200 }
            }
        }
    }
}
