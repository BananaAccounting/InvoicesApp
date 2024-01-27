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

Item {
   id: control

   property var contextMenu: baseContextMenu

   property alias cursorVisible: textArea.cursorVisible
   property alias cursorPosition: textArea.cursorPosition
   property alias font: textArea.font
   property alias placeholderText : textArea.placeholderText
   property alias readOnly: textArea.readOnly
   property alias text: textArea.text
   property alias textFormat  : textArea.textFormat
   property alias selectecText: textArea.selectedText
   property alias wrapMode: textArea.wrapMode

   property var keyNavigationTab: null
   property var keyNavigationBackTab: null

   property bool _copyAllOnCopy: false

   signal textEdited()

   ScrollView {
      id: scrollView
      clip: true
      anchors.fill: parent

      background : Rectangle {
         color: Stylesheet.baseColor
         border.color: scrollView.activeFocus ? "#354793" : "#bdbebf"
         border.width: scrollView.activeFocus ? 1 : 1
         radius: scrollView.activeFocus ? 2 * Stylesheet.pixelScaleRatio : 1
      }

      TextArea {
         id: textArea
         selectByMouse: true
         persistentSelection: false
         implicitWidth: scrollView.availableWidth

         KeyNavigation.priority: KeyNavigation.BeforeItem
         KeyNavigation.tab: keyNavigationTab
         KeyNavigation.backtab: keyNavigationBackTab

         color: Stylesheet.textColor
         selectionColor : Stylesheet.selectionColor
         selectedTextColor: Stylesheet.selectedTextColor

         onTextChanged: {
            if (focus)
               control.textEdited()
         }

         onActiveFocusChanged: {
            if (!activeFocus && !persistentSelection)
               deselect()
         }
      }
   }

   MouseArea {
      anchors.fill: parent
      acceptedButtons: control.contextMenu ? Qt.RightButton : Qt.NoButton
      cursorShape: textArea.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor

      onPressed: {
         if (mouse.button === Qt.RightButton) {
            mouse.accepted = true
            openMenu(mouse)
         }
      }

      function openMenu(mouse) {
         if (control.contextMenu) {
            if (!scrollView.focus) {
               scrollView.forceActiveFocus()
               textArea.forceActiveFocus()
               if (!textArea.readOnly) {
                  textArea.selectAll()
               } else {
                  _copyAllOnCopy = true
               }
            } else {
               textArea.persistentSelection = true
            }

            control.contextMenu.x = mouse.x
            control.contextMenu.y = mouse.y
            control.contextMenu.open()
         }
      }
   }

   Connections {
      target: contextMenu
      function onClosed() {
         scrollView.forceActiveFocus()
         textArea.forceActiveFocus()
         textArea.persistentSelection = false
         _copyAllOnCopy = false
      }
   }

   Menu {
      id: baseContextMenu
      focus: false

      MenuItem {
         text: qsTr("Cut")
         enabled: !textArea.readOnly && textArea.selectedText.length > 0
         onClicked: textArea.cut()
      }

      MenuItem {
         text: qsTr("Copy")
         enabled: textArea.readOnly || textArea.selectedText.length > 0
         onClicked: {
            if (_copyAllOnCopy || textArea.selectedText.length === 0) {
               textArea.selectAll()
               textArea.copy()
               textArea.deselect()
            } else {
               textArea.copy()
            }
         }
      }

      MenuItem {
         text: qsTr("Paste")
         enabled: !textArea.readOnly && textArea.canPaste
         onClicked: textArea.paste()
      }
   }

   function copy() {
      if (_copyAllOnCopy || selectecText.length === 0) {
         textArea.selectAll()
         textArea.copy()
         textArea.deselect()
      } else {
         textArea.copy()
      }
   }

   function length() {
      return textArea.length()
   }

   function select(start, end) {
      textArea.select(start, end)
   }
}
