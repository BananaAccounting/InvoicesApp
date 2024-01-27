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
import "../base/languages.js" as Languages
import "../base/settings.js" as Settings

Window {
    id: dialog
    title: qsTr("Translations")

    required property string trId
    required property AppSettings appSettings
    property string programLanguage: ""
    property string documentLanguage: ""
    property var languages: Languages.getUsedLanguagesCodes()

    color: Stylesheet.baseColor

    property int stylePropertyWidth: 220 * Stylesheet.pixelScaleRatio
    property int styleSectionSeparatorHeight: 4 * Stylesheet.defaultMargin

    signal translationChanged()

    Item {
        focus: true // to enable key events handling
        anchors.fill: parent

        Keys.onEscapePressed: {
            dialog.visible = false
        }

        Keys.onReleased: {
            if (event.key === Qt.Key_Help || event.key === Qt.Key_F1) {
                showHelp()
                event.accepted = true
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Stylesheet.defaultMargin

            StyledLabel{
                text: Settings.getTranslationDescription(appSettings ? appSettings.data : null, trId, programLanguage);
                font.bold: true
            }

            RowLayout {
                StyledLabel{
                    text: qsTr("Id")
                    Layout.fillWidth: true
                }

                StyledTextField {
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: stylePropertyWidth
                    text: trId
                    borderless: true
                    readOnly: true
                }

            }

            RowLayout {
                StyledLabel{
                    text: Languages.getLanguageName(programLanguage) +
                          (programLanguage === documentLanguage ? " *" : "")
                    Layout.fillWidth: true
                }

                StyledTextField {
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: stylePropertyWidth
                    text: getTranslatedText(programLanguage)
                    onEditingFinished: {
                        if (modified) {
                            setTranslatedText(programLanguage, text)
                            translationChanged()
                        }
                        focus = false
                    }
                }
            }

            ScrollView {
                id: scrollView
                clip: true

                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    width: scrollView.availableWidth
                    height: scrollView.availableHeight

                    StyledLabel{
                        text: qsTr("Other languages")
                        font.bold: true
                        Layout.topMargin: styleSectionSeparatorHeight / 2
                    }

                    Repeater {
                        model: languages
                        RowLayout {
                            visible: modelData != programLanguage

                            StyledLabel{
                                text: Languages.getLanguageName(modelData) +
                                      (modelData === documentLanguage ? " *" : "")
                                Layout.fillWidth: true
                                visible: modelData != programLanguage
                            }

                            StyledTextField {
                                Layout.alignment: Qt.AlignRight
                                implicitWidth: stylePropertyWidth
                                text: getTranslatedText(modelData)
                                visible: modelData != programLanguage
                                onEditingFinished: {
                                    if (modified) {
                                        setTranslatedText(modelData, text)
                                        translationChanged()
                                    }
                                    focus = false
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
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
                    text: qsTr("Close")
                    onClicked: {
                        dialog.visible = false
                    }
                }
            }
        }
    }

    function getTranslatedText(lang) {
        if (appSettings) {
            let text = Settings.getTranslatedText(appSettings.data, trId, lang);
            if (text)
                return text;
        }
        return trId;
    }

    function setTranslatedText(lang, text) {
        if (appSettings) {
            Settings.setTranslatedText(appSettings.data, trId, lang, text);
            appSettings.modified = true;
            appSettings.signalTranslationsChanged++;
        }
    }

    function showHelp() {
        Banana.Ui.showHelp("dlginvoiceedit::translations");
    }

}
