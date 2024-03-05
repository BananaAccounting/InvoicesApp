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
import QtQuick.Window

import "./components"

Window {
    id: dialog
    title: qsTr("Source")

    property bool isModified: false
    property bool isReadOnly: false

    property alias text: sourceTextArea.text
    property alias font: sourceTextArea.font

    property string format: ""

    signal accepted;
    signal rejected;

    color: Stylesheet.baseColor

    Item {
        focus: true // to enable key events handling
        anchors.fill: parent

        Keys.onReleased: {
            if (event.key === Qt.Key_Help || event.key === Qt.Key_F1) {
                showHelp()
                event.accepted = true
             }
        }

        ColumnLayout {
            focus: true // to enable key events handling
            anchors.fill: parent
            anchors.margins: Stylesheet.defaultMargin

            StyledScrollableTextArea {
                id: sourceTextArea
                Layout.fillHeight: true
                Layout.fillWidth: true
                readOnly: isReadOnly
                font.family: "Courier"
                onTextEdited: {
                    dialog.isModified = true
                }
            }

            SearchBar {
                id: searchBar
                Layout.fillWidth: true
                Layout.bottomMargin: 5 * Stylesheet.pixelScaleRatio
                textControl: sourceTextArea
                visible: false
                onDone : {
                    source_find_button.visible = true
                }
            }

            RowLayout {
                Layout.alignment:  Qt.AlignRight | Qt.AlignBottom
                Layout.rightMargin: 0
                Layout.fillWidth: true

                StyledButton {
                    text: qsTr("Help")
                    onClicked: showHelp()
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledButton {
                    text: qsTr("Find")
                    onClicked: {
                        visible = false
                        searchBar.visible = true
                    }
                    Shortcut {
                        sequence: StandardKey.Find
                        onActivated: {
                            parent.visible = false
                            searchBar.visible = true
                        }
                    }
                }

                StyledButton {
                    text: qsTr("Copy")
                    onClicked: {
                        sourceTextArea.copy()
                    }
                }

                StyledButton {
                    text: qsTr("Save")
                    enabled: dialog.isModified
                    visible: !isReadOnly
                    onClicked: {
                        try {
                            if (format == "json") {
                                JSON.parse(dialog.text)
                            }
                            dialog.isModified = false
                            dialog.visible = false
                            accepted()
                        } catch (err) {
                            errorMessageDialog.text = err.toString();
                            errorMessageDialog.visible = true
                        }
                    }
                }

                StyledButton {
                    text: qsTr("Cancel")
                    visible: !isReadOnly && dialog.isModified
                    enabled: dialog.isModified
                    onClicked: {
                        dialog.isModified = false
                        dialog.visible = false
                        rejected()
                    }
                }

                StyledButton {
                    text: qsTr("Close")
                    visible: isReadOnly || !dialog.isModified
                    Shortcut {
                        enabled: !searchBar.visible
                        sequence: [StandardKey.Cancel]
                        onActivated: dialog.visible = false
                    }
                    onClicked: {
                        dialog.isModified = false
                        dialog.visible = false
                        rejected()
                    }
                }
            }
        }
    }

    SimpleMessageDialog { // Error message dialog
        id: errorMessageDialog
        visible: false
    }

    function showHelp() {
        Banana.Ui.showHelp("dlginvoicesource");
    }

}
