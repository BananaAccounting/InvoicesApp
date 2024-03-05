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

TextField {
   id: textField
   implicitHeight: 28 * Stylesheet.pixelScaleRatio

   selectByMouse: true
   property bool selected: false
   property bool borderless: false
   property bool modified: false

   color: Stylesheet.textColor
   selectionColor : Stylesheet.selectionColor
   selectedTextColor: Stylesheet.selectedTextColor

   background: Rectangle {
      color: Stylesheet.baseColor
      border.color: textField.activeFocus || selected ? "#354793" : borderless ? Stylesheet.baseColor : "#bdbebf"
      border.width: 1
      radius: 2.0 * Stylesheet.pixelScaleRatio
   }

   /** Context menu of text field */
   property var contextMenu: baseContextMenu

   property bool _copyAllOnCopy: false

   Keys.onReturnPressed: function(event) {
       focus = false
   }

   Keys.onEscapePressed: function(event){
       undo()
       modified = false
       focus = false
       event.accepted = true
   }

   Keys.onReleased: function(event) {
      if (event.key === Qt.Key_Home) {
         cursorPosition = 0
         event.accepted = true
      } else if (event.key === Qt.Key_End) {
         cursorPosition = text.length
         event.accepted = true
      }
   }

   // If the text is widther than the widget we have to position the cursor to 0
   // so that the begin of the text is showed, if not the text is aligned to the right
   autoScroll: focus

   onEditingFinished: function() {
       cursorPosition = 0
       ensureVisible(0)
   }

   onTextEdited: function() {
       modified = true
   }

   onFocusChanged: function() {
       if (!focus) {
           modified = false
       }
   }

   MouseArea {
      anchors.fill: parent
      acceptedButtons: textField.contextMenu ? Qt.RightButton : Qt.NoButton

      onPressed: {
         if (mouse.button === Qt.RightButton) {
            mouse.accepted = true
            openMenu(mouse)
         }
      }

      function openMenu(mouse) {
         textField.persistentSelection = true
         if (!textField.focus) {
            textField.forceActiveFocus()
            if (!textField.readOnly) {
               textField.selectAll()
            } else {
               _copyAllOnCopy = true
            }
         }
         textField.contextMenu.x = mouse.x
         textField.contextMenu.y = mouse.y
         textField.contextMenu.open()
      }
   }

   Connections {
      target: contextMenu
      function onClosed()  {
         textField.forceActiveFocus()
         textField.persistentSelection = false
         _copyAllOnCopy = false
      }
   }

   Menu {
      id: baseContextMenu
      focus: false

      MenuItem {
         text: qsTr("Cut")
         enabled: !textField.readOnly && textField.selectedText.length > 0
         onClicked: textField.cut()
         palette.text: enabled ? Stylesheet.textColor : "grey"
      }

      MenuItem {
         text: qsTr("Copy")
         enabled: textField.readOnly || textField.selectedText.length > 0
         palette.text: enabled ? Stylesheet.textColor : "grey"
         onClicked: {
            if (_copyAllOnCopy || textField.selectedText.length === 0) {
               textField.selectAll()
               textField.copy()
               textField.deselect()
            } else {
               textField.copy()
            }
         }
      }

      MenuItem {
         text: qsTr("Paste")
         enabled: !textField.readOnly && textField.canPaste
         palette.text: enabled ? Stylesheet.textColor : "grey"
         onClicked: textField.paste()
      }
   }
}
