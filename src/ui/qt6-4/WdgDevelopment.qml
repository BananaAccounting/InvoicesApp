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

import "../base/invoice.js" as Invoice

Item {
    id: root

    required property AppSettings appSettings
    required property Invoice invoice
    required property DevSettings devSettings

    // Style properties
    property int stylePropertyWidth: 200 * Stylesheet.pixelScaleRatio
    property int styleButtonMinWidth: 140 * Stylesheet.pixelScaleRatio
    property int styleSectionSeparatorHeight: 4 * Stylesheet.defaultMargin
    property int styleColumnSpacing: 2.5 * Stylesheet.defaultMargin
    property int styleRowSpacing: 0.5 * Stylesheet.defaultMargin

    signal goToHome()

    ScrollView {
        id: scrollView
        clip: true

        anchors.fill: parent
        anchors.margins: Stylesheet.defaultMargin

        ColumnLayout {
            width: scrollView.availableWidth
            height: scrollView.availableHeight

            StyledLabel {
                text: "Info"
                font.bold: true
                Layout.bottomMargin: styleRowSpacing
            }

            RowLayout {
                StyledLabel {
                    text: "Publishing date"
                    Layout.fillWidth: true
                }

                StyledTextField {
                    text: Banana.script.getParamValue('pubdate');
                    readOnly: true
                    borderless: true
                }
            }

            RowLayout {
                StyledLabel {
                    text: "Extention's path"
                    Layout.fillWidth: true
                }

                StyledTextField {
                    text: Banana.script.getPath ? Banana.script.getPath() : "";
                    readOnly: true
                    borderless: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: styleSectionSeparatorHeight / 2
                Layout.bottomMargin: styleSectionSeparatorHeight / 2
                height: 1
                color: Stylesheet.buttonColor
            }

            StyledLabel {
                text: "Development settings"
                font.bold: true
                Layout.bottomMargin: styleRowSpacing
            }

            RowLayout {
                StyledLabel {
                    text: "Disable advaced plan license"
                    Layout.fillWidth: true
                }

                StyledSwitch {
                    enabled: Banana.application.isInternal
                    checked: devSettings.disableAdvancedPlanLicense
                    onToggled: devSettings.disableAdvancedPlanLicense = checked
                }
            }

            RowLayout {
                StyledLabel {
                    text: "Disable isInternal flag"
                    Layout.fillWidth: true
                }

                StyledSwitch {
                    enabled: Banana.application.isInternal
                    checked: devSettings.disableIsInternalVersionFlag
                    onToggled: {
                        devSettings.disableIsInternalVersionFlag = checked
                        goToHome()
                    }
                }
            }

            RowLayout {
                StyledLabel {
                    text: "Show version notification bar"
                    Layout.fillWidth: true
                }

                StyledSwitch {
                    enabled: Banana.application.isInternal
                    checked: appSettings.isNotificationVisible("show_updated_version_installed")
                    onToggled: {
                        appSettings.setNotificationVisible("show_updated_version_installed", checked)
                    }
                }
            }

            RowLayout {
                StyledLabel {
                    text: "Switch invoice read only flag"
                    Layout.fillWidth: true
                }

                StyledSwitch {
                    enabled: Banana.application.isInternal
                    checked: invoice.isReadOnly
                    onToggled: {
                        invoice.setIsReadOnly(!invoice.isReadOnly)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: styleSectionSeparatorHeight / 2
                Layout.bottomMargin: styleSectionSeparatorHeight / 2
                height: 1
                color: Stylesheet.buttonColor
            }

            StyledLabel {
                text: "Development tools"
                font.bold: true
            }

            RowLayout {
                StyledLabel {
                    text: "Show invoice json that will be printed"
                    Layout.fillWidth: true
                }

                StyledButton {
                    text: "Show print json"
                    Layout.minimumWidth: styleButtonMinWidth
                    onClicked: {
                        let printedJsonObj = JSON.parse(JSON.stringify(invoice.json));
                        Invoice.invoicePrepareForPrinting(printedJsonObj);

                        dlgEditJson.isReadOnly = true
                        dlgEditJson.text = JSON.stringify(printedJsonObj, null, "   ")
                        dlgEditJson.format = "json";
                        dlgEditJson.isModified = false
                        dlgEditJson.visible = true
                    }
                }
            }

            RowLayout {
                StyledLabel {
                    text: "Show pixel metrics"
                    Layout.fillWidth: true
                }

                StyledButton {
                    text: "Show pixel metrics"
                    Layout.minimumWidth: styleButtonMinWidth
                    onClicked: {
                        dlgPixelMetrics.visible = true
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

        }
    }

    DlgEditSource {
        id: dlgEditJson
        modality: Qt.WindowModal
        height: root.height - 50 * Stylesheet.pixelScaleRatio
        width: root.width - 200 * Stylesheet.pixelScaleRatio

        font.family: "Courier"
        onAccepted: visible = false
    }

    DlgPixelMetrics {
        id: dlgPixelMetrics
    }

    SimpleMessageDialog {
        id: messaggeDialog
        visible: false
    }
}
