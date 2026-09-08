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
 * Clickable heading that opens and closes a group of fields below it.
 *
 * Used to break the invoice form into sections when it is stacked into a single column,
 * where the whole form is far taller than the screen. The section that is open is the
 * one being worked on; the rest collapse to a single line each.
 *
 * Holds its own open/closed state in 'expanded', which the fields of the section read to
 * decide whether to show themselves.
 */
Item {
    id: header

    property string title: ""
    property bool expanded: false

    // The same height as a button. Four of these closed sit between the top of the form
    // and the items table, so the height is worth having; below this it would start to
    // read as cramped, and would fall short of a comfortable target for a fingertip.
    implicitHeight: 34 * Stylesheet.pixelScaleRatio
    implicitWidth: titleLabel.implicitWidth + indicatorBox.width + 3 * Stylesheet.defaultMargin

    Rectangle { // Rule above the heading, marking where the previous section ended
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: Stylesheet.separatorColor
    }

    Rectangle { // Hover cue, so the heading reads as something that can be clicked
        anchors.fill: parent
        anchors.topMargin: 1
        radius: Stylesheet.cornerRadiusSmall
        color: clickArea.containsMouse ? Stylesheet.hoverColor : "transparent"
    }

    Item {
        // On the trailing edge, so that the title can start flush with the fields of the
        // section below it. With the indicator first, the heading began a couple of dozen
        // points further right than the content it heads, which reads as a hierarchy the
        // wrong way round. Indenting the fields instead would have been the other way to
        // line them up, but horizontal room is the one thing a phone has none of.
        //
        // The indicator shifts its own y when it rotates open, so it cannot be anchored
        // directly: it is centred through this box instead.
        id: indicatorBox
        width: 12 * Stylesheet.pixelScaleRatio
        height: 12 * Stylesheet.pixelScaleRatio
        anchors.right: parent.right
        anchors.rightMargin: Stylesheet.defaultMargin / 2
        anchors.verticalCenter: parent.verticalCenter

        StyledBranchIndicator {
            expanded: header.expanded
        }
    }

    StyledLabel {
        id: titleLabel
        anchors.left: parent.left
        anchors.right: indicatorBox.left
        anchors.rightMargin: Stylesheet.defaultMargin
        anchors.verticalCenter: parent.verticalCenter
        text: header.title
        // Bold but not accent coloured: a heading organises the form, it is not the thing
        // the document is about. The accent stays on the total.
        font.bold: true
        elide: Text.ElideRight
    }

    MouseArea {
        // Declared last so it sits above the indicator's own mouse area: the whole
        // heading toggles the section, and the triangle cannot toggle itself separately
        // and break the binding that keeps it in step.
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: header.expanded = !header.expanded
    }
}
