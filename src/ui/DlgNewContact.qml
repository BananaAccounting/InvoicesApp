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

import "./components"

/**
 * Asks for the id a new contact should take, and shows the address it will be created from.
 *
 * It only asks: the row is written by whoever opened this dialog, through the
 * DocumentChange, so that a contact created here reaches the Contacts table the same way
 * everything else this dialog changes does - when the window is closed.
 */
Dialog {
    id: dialog

    /** The address the contact will be made of, as one line, for the user to check. */
    property string addressSummary: ""

    /** Where the dialog sits when it is not centred - just under the bar above, say. */
    property real topY: 0

    /** Centre it in its parent instead. Used on a narrow screen, where the top of the
        screen belongs to the notch. */
    property bool centered: false

    signal contactConfirmed(string contactId)

    x: Math.max(Stylesheet.defaultMargin, (parent.width - width) / 2)
    y: centered ? Math.max(Stylesheet.defaultMargin, (parent.height - height) / 2) : topY

    // Never wider or taller than the window it is shown in: centring something wider than
    // its parent puts its left edge at a negative position, and the dialog then hangs off
    // both sides at once.
    width: Math.min(400 * Stylesheet.pixelScaleRatio,
                    parent.width - 2 * Stylesheet.defaultMargin)
    height: Math.min(230 * Stylesheet.pixelScaleRatio,
                     parent.height - 2 * Stylesheet.defaultMargin)

    modal: true
    visible: false

    background: Rectangle {
        color: Stylesheet.baseColor
        radius: Stylesheet.cornerRadius
        border.color: Stylesheet.borderColor
    }

    /** Opens the dialog on a suggested id and the address it would save. */
    function openFor(suggestedId, summary) {
        addressSummary = summary ? summary : ""
        idField.text = suggestedId ? suggestedId : ""
        visible = true
        idField.forceActiveFocus()
        idField.selectAll()
    }

    contentItem: ColumnLayout {
        spacing: Stylesheet.spacingBase

        StyledLabel {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            text: qsTr("A new contact is created from the address of this document.")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Stylesheet.spacingBase

            StyledLabel {
                text: qsTr("Contact id")
            }

            StyledTextField {
                id: idField
                Layout.fillWidth: true
                Layout.minimumWidth: 60 * Stylesheet.pixelScaleRatio
                // Return accepts the dialog, as it would in any other small form.
                Keys.onReturnPressed: function(event) {
                    if (idField.text.trim().length > 0) {
                        dialog.accept()
                        event.accepted = true
                    }
                }
            }
        }

        StyledLabel {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            // The address itself, not the name of a field: full strength.
            color: Stylesheet.textColor
            text: dialog.addressSummary
        }

        Item {
            // Takes whatever height is left, so the fields stay at the top of the dialog.
            Layout.fillHeight: true
        }
    }

    footer: DialogButtonBox {
        delegate: StyledButton {}
        background: Rectangle {
            x: 1
            y: 1
            color: Stylesheet.baseColor
        }

        StyledButton {
            text: qsTr("Create")
            primary: true
            // A contact with no id cannot be found again, and the document would point at
            // nothing.
            enabled: idField.text.trim().length > 0
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }

        StyledButton {
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
    }

    onAccepted: {
        visible = false
        contactConfirmed(idField.text.trim())
    }

    onRejected: {
        visible = false
    }
}
