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
 * A titled panel that groups the fields belonging together: the customer, the document, the
 * totals. The children are declared directly inside it and are laid out in one column, so a
 * card is written the same way wherever it is used.
 *
 * With 'collapsible' the title opens and closes the card, and nothing below it is drawn while
 * it is closed. 'plain' drops the frame and the padding and makes the title a quiet
 * disclosure line: that is the form used for the secondary fields of a card, nested inside
 * the card itself, so the card has one prominent frame and not two.
 */
Rectangle {
    id: card

    property string title: ""
    property bool collapsible: false
    property bool expanded: true

    /** No frame, no padding, quiet title: a group nested inside another card. */
    property bool plain: false

    /** Children go here, so a card is written like any other layout. */
    default property alias cardContent: contentColumn.data

    /** Between the children of the card. Tight by default: they are fields of one group. */
    property alias contentSpacing: contentColumn.spacing

    readonly property int cardPadding: plain ? 0 : 1.4 * Stylesheet.defaultMargin
    readonly property int indicatorSize: 12 * Stylesheet.pixelScaleRatio

    /* A card is a surface of its own, a shade away from the page, with a frame quiet enough
       not to compete with the fields inside it. Drawn rather than outlined: a plain outline
       on the colour of the page left the groups of the form hard to tell apart at a glance. */
    color: plain ? "transparent" : Stylesheet.surfaceColor
    radius: plain ? 0 : 1.5 * Stylesheet.cornerRadius
    border.width: plain ? 0 : 1
    border.color: Stylesheet.separatorColor

    /* A fixed request rather than the width of the widest child: a label holding a whole
       sentence would otherwise decide how wide the card asks to be, and two cards side by
       side would stop sharing the row evenly. The children shrink with the card instead. */
    implicitWidth: plain ? 0 : 320 * Stylesheet.pixelScaleRatio
    implicitHeight: layoutColumn.implicitHeight + 2 * cardPadding

    ColumnLayout {
        id: layoutColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.cardPadding

        spacing: Stylesheet.spacingBase + Stylesheet.spacingTight

        Item { // Title, and the disclosure indicator when the card can be closed
            id: titleRow

            visible: card.title.length > 0
            Layout.fillWidth: true
            implicitHeight: Math.max(titleLayout.implicitHeight, card.indicatorSize)

            RowLayout {
                id: titleLayout
                anchors.fill: parent
                spacing: Stylesheet.spacingBase

                Item {
                    // Leading indicator of a nested group, where it reads as a disclosure
                    // triangle in front of its line.
                    visible: card.collapsible && card.plain
                    implicitWidth: visible ? card.indicatorSize : 0
                    implicitHeight: card.indicatorSize

                    StyledBranchIndicator {
                        expanded: card.expanded
                        color: Stylesheet.accentColor
                    }
                }

                StyledLabel {
                    id: titleLabel
                    Layout.fillWidth: true
                    text: card.title
                    // A card's own title is a heading: full strength and bold. A nested
                    // group is a quiet line instead, like the label of a field.
                    /* A nested group that opens and closes is a link, and its title is
                       the whole of it: accent coloured, so that something which can be
                       clicked does not read as inert text. The title of a card stays plain
                       - there the triangle on the far side carries the affordance. */
                    color: card.plain ? (card.collapsible ? Stylesheet.accentColor
                                                          : Stylesheet.labelColor)
                                      : Stylesheet.textColor
                    font: card.plain ? Stylesheet.labelFont : Stylesheet.cardTitleFont
                    elide: Text.ElideRight
                }

                Item {
                    // Trailing indicator of a card, on the edge opposite its title.
                    visible: card.collapsible && !card.plain
                    implicitWidth: visible ? card.indicatorSize : 0
                    implicitHeight: card.indicatorSize

                    StyledBranchIndicator {
                        expanded: card.expanded
                        color: Stylesheet.accentColor
                    }
                }
            }

            MouseArea {
                // Declared last so it sits above the indicator's own mouse area: the whole
                // line opens and closes the card, and the triangle cannot toggle itself
                // separately and break the binding that keeps it in step.
                anchors.fill: parent
                enabled: card.collapsible
                hoverEnabled: card.collapsible
                cursorShape: Qt.PointingHandCursor
                onClicked: card.expanded = !card.expanded
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            // An invisible child is left out of the layout entirely, so a closed card is
            // exactly as tall as its title.
            visible: card.expanded
            spacing: Stylesheet.spacingTight
        }
    }
}
