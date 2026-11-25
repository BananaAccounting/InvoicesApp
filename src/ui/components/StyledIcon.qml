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
import QtQuick.Shapes

import "."

/**
 * One icon of the toolbar, drawn rather than loaded.
 *
 * Drawn because an image would have to be a file of its own, at several sizes, in two
 * colours for the light and the dark theme - and because the dialog is scaled by
 * pixelScaleRatio, which a bitmap does not follow. Here the shape is laid out on a square of
 * whatever size is asked for and takes the colour it is given, so one icon serves every
 * platform, both themes and every screen.
 *
 * Mostly rectangles: at this size a straight edge is all that survives anyway, and a
 * Rectangle costs less than a path. Shapes are used only where a line is not straight.
 */
Item {
    id: root

    /** Which icon: new, copy, delete, print, convert, settings. */
    property string name: ""

    property color color: Stylesheet.textColor

    /** The side of the square the icon is drawn on. */
    property real size: 16 * Stylesheet.pixelScaleRatio

    /** The weight of a line, never thinner than one pixel. */
    readonly property real stroke: Math.max(1, Math.round(size / 9))

    implicitWidth: size
    implicitHeight: size

    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch (root.name) {
            case "new": return newIcon
            case "copy": return copyIcon
            case "delete": return deleteIcon
            case "print": return printIcon
            case "convert": return convertIcon
            case "settings": return settingsIcon
            case "help": return helpIcon
            case "search": return searchIcon
            }
            return null
        }
    }

    Component { // A lens and its handle
        id: searchIcon
        Item {
            Rectangle {
                x: parent.width * 0.04
                y: parent.height * 0.04
                width: parent.width * 0.62
                height: width
                radius: width / 2
                color: "transparent"
                border.width: root.stroke
                border.color: root.color
            }

            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeColor: root.color
                    strokeWidth: root.stroke * 1.2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: root.size * 0.6
                    startY: root.size * 0.6
                    PathLine { x: root.size * 0.93; y: root.size * 0.93 }
                }
            }
        }
    }

    Component { // A question mark in a ring
        id: helpIcon
        Item {
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: root.stroke
                border.color: root.color
            }
            Text {
                anchors.centerIn: parent
                text: "?"
                color: root.color
                font: Stylesheet.scaledFont(0.95, Font.DemiBold)
            }
        }
    }

    Component { // A plus: something that was not there before
        id: newIcon
        Item {
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: root.stroke
                radius: height / 2
                color: root.color
            }
            Rectangle {
                anchors.centerIn: parent
                width: root.stroke
                height: parent.height * 0.8
                radius: width / 2
                color: root.color
            }
        }
    }

    Component { // Two sheets, the one behind showing at its corner
        id: copyIcon
        Item {
            Shape {
                anchors.fill: parent
                // The sheet behind, drawn as the two edges of it that are not covered:
                // a closed outline would cross the sheet in front and come out muddy.
                ShapePath {
                    strokeColor: root.color
                    strokeWidth: root.stroke
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: root.size * 0.06
                    startY: root.size * 0.68
                    PathLine { x: root.size * 0.06; y: root.size * 0.06 }
                    PathLine { x: root.size * 0.68; y: root.size * 0.06 }
                }
            }

            Rectangle { // The sheet in front
                x: parent.width * 0.3
                y: parent.height * 0.3
                width: parent.width * 0.64
                height: parent.height * 0.64
                radius: root.stroke
                color: "transparent"
                border.width: root.stroke
                border.color: root.color
            }
        }
    }

    Component { // A bin: lid, handle, body
        id: deleteIcon
        Item {
            Rectangle { // handle
                x: parent.width * 0.36
                y: parent.height * 0.08
                width: parent.width * 0.28
                height: root.stroke
                color: root.color
            }
            Rectangle { // lid
                x: parent.width * 0.1
                y: parent.height * 0.22
                width: parent.width * 0.8
                height: root.stroke
                radius: height / 2
                color: root.color
            }
            Rectangle { // body
                x: parent.width * 0.2
                y: parent.height * 0.32
                width: parent.width * 0.6
                height: parent.height * 0.6
                radius: root.stroke
                color: "transparent"
                border.width: root.stroke
                border.color: root.color
            }
        }
    }

    Component { // A printer: the sheet going in, the machine, the sheet coming out
        id: printIcon
        Item {
            Rectangle { // the sheet above
                x: parent.width * 0.26
                y: parent.height * 0.06
                width: parent.width * 0.48
                height: parent.height * 0.22
                color: "transparent"
                border.width: root.stroke
                border.color: root.color
            }
            Rectangle { // the machine
                x: parent.width * 0.08
                y: parent.height * 0.32
                width: parent.width * 0.84
                height: parent.height * 0.34
                radius: root.stroke
                color: "transparent"
                border.width: root.stroke
                border.color: root.color
            }
            Rectangle { // the sheet coming out
                // Starts where the machine ends rather than over it: an opaque fill to
                // cover what is behind would be the colour of the page, which is not the
                // colour of the bar the icon sits on.
                x: parent.width * 0.26
                y: parent.height * 0.66
                width: parent.width * 0.48
                height: parent.height * 0.28
                color: "transparent"
                border.width: root.stroke
                border.color: root.color
            }
        }
    }

    Component { // An arrow to the right: this document becomes another one
        id: convertIcon
        Item {
            Rectangle {
                x: parent.width * 0.06
                y: (parent.height - root.stroke) / 2
                width: parent.width * 0.58
                height: root.stroke
                radius: height / 2
                color: root.color
            }

            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: root.color
                    startX: root.size * 0.52
                    startY: root.size * 0.22
                    PathLine { x: root.size * 0.94; y: root.size * 0.5 }
                    PathLine { x: root.size * 0.52; y: root.size * 0.78 }
                    PathLine { x: root.size * 0.52; y: root.size * 0.22 }
                }
            }
        }
    }

    Component { // Sliders: the settings of the extension
        id: settingsIcon
        Item {
            Repeater {
                model: [0.22, 0.5, 0.78]        // the three rows
                delegate: Item {
                    anchors.fill: parent

                    readonly property real rowY: modelData
                    // The knob of each row sits at a different place along it, or the three
                    // read as a list rather than as something to set.
                    readonly property real knobX: index === 1 ? 0.3 : (index === 0 ? 0.64 : 0.46)

                    Rectangle {
                        x: parent.width * 0.08
                        y: parent.height * parent.rowY - root.stroke / 2
                        width: parent.width * 0.84
                        height: root.stroke
                        radius: height / 2
                        color: root.color
                    }

                    Rectangle {
                        width: root.stroke * 2.6
                        height: width
                        radius: width / 2
                        x: parent.width * parent.knobX - width / 2
                        y: parent.height * parent.rowY - height / 2
                        color: root.color
                    }
                }
            }
        }
    }
}
