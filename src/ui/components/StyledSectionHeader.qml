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
import QtQuick.Layouts

import "."

/**
 * Clickable heading that opens and closes a group of fields below it, used where the form
 * is stacked into a single column and is far taller than the screen. Holds its own state
 * in 'expanded', which the fields of the section read to decide whether to show themselves.
 */
Item {
    id: header

    property string title: ""
    property bool expanded: false

    // The same height as a button. Four of these closed sit between the top of the form
    // and the items table, so the height is worth having; below this it would start to
    // read as cramped, and would fall short of a comfortable target for a fingertip.
    implicitHeight: 34 * Stylesheet.pixelScaleRatio

    /* The headings do not all live in the same layout, and those layouts space their rows
       differently, so the gap came out different above each of them. What is missing to reach
       a section's spacing is asked for here, and follows the layout if it ever changes. */
    Layout.topMargin: Math.max(0, Stylesheet.spacingSection - parentSpacing)
    readonly property int parentSpacing: !parent ? 0 :
                                             parent.rowSpacing !== undefined ? parent.rowSpacing :
                                                 parent.spacing !== undefined ? parent.spacing : 0
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
        // On the trailing edge, so the title starts flush with the fields it heads: with the
        // indicator first the heading began further right than its own content. The indicator
        // shifts its y when it rotates, so it cannot be anchored: this box centres it.
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
        // Full strength and in the heading font, unlike the labels below it. Not accent
        // coloured: a heading organises the form, the accent stays on the total.
        color: Stylesheet.textColor
        font: Stylesheet.sectionTitleFont
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
