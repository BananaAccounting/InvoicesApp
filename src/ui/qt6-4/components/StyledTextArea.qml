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

TextArea {
   id: textArea
   selectByMouse: true

   color: Stylesheet.textColor
   selectionColor : Stylesheet.selectionColor
   selectedTextColor: Stylesheet.selectedTextColor
   wrapMode: TextEdit.Wrap

   background: Rectangle {
      color: Stylesheet.baseColor
      border.color: textArea.activeFocus | selected ? "#354793" : "#bdbebf"
      border.width: 1
      radius: 2.0 * Stylesheet.pixelScaleRatio
   }


   property bool modified: false
   property bool selected: false
   property var contextMenu: baseContextMenu
   property bool _copyAllOnCopy: false

   signal textEdited()

   onTextChanged: function() {
      if (focus) {
         textArea.textEdited()
         modified = true
      }
   }

   onFocusChanged: function() {
       if (focus)
           modified = false
   }

   Keys.onEscapePressed: function(event) {
       undo()
       modified = false
       focus = false
       event.accepted = true
   }

   MouseArea {
      anchors.fill: parent
      acceptedButtons: textArea.contextMenu ? Qt.RightButton : Qt.NoButton
      cursorShape: textArea.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor

      onPressed: {
         if (mouse.button === Qt.RightButton) {
            mouse.accepted = true
            openMenu(mouse)
         }
      }

      function openMenu(mouse) {
         textArea.persistentSelection = true
         if (!textArea.focus) {
            textArea.forceActiveFocus()
            if (!textArea.readOnly) {
               textArea.selectAll()
            } else {
               _copyAllOnCopy = true
            }
         }
         textArea.contextMenu.x = mouse.x
         textArea.contextMenu.y = mouse.y
         textArea.contextMenu.open()
      }
   }

   Connections {
      target: contextMenu
      function onClosed() {
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
}
