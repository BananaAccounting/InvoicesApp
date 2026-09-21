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
      /* Android draws the dialog with the Material style, which works out the space above
         the text from the height the background asks for: (implicitBackgroundHeight -
         height of the placeholder) / 2. Its own background asks for the height of a text
         field; a plain Rectangle asks for nothing at all, so the division came out
         negative and the text was drawn above the box, with the cursor outside it. The
         box was left shorter than its own text as well, since the height of the field is
         its content plus those paddings.

         The height of a control is asked for instead, the one used for a section heading
         or a menu entry. Material's own 56 would have been the other candidate, but it
         would make every description in the items table that tall.

         Nothing is asked for on the other platforms: their styles pad by fixed amounts
         and never read this, and a height here would only make an empty field taller
         than it is today. */
      implicitHeight: Qt.platform.os === "android" ? 34 * Stylesheet.pixelScaleRatio : 0

      color: Stylesheet.baseColor
      // Highlight real focus only - see StyledTextField: "selected" is bound to the
      // items table's current cell, which stays set after the focus moved away.
      border.color: textArea.activeFocus ? Stylesheet.accentColor : Stylesheet.borderColor
      border.width: textArea.activeFocus ? 2 : 1
      radius: Stylesheet.cornerRadiusSmall

      Behavior on border.color {
          ColorAnimation { duration: 120 }
      }
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

      // On the desktop the style draws the menu from its palette, which stays light in dark
      // mode: the dialog's own colours are handed to it, as for the menus in DlgInvoice.qml.
      palette.window: Stylesheet.menuWindowColor
      palette.windowText: Stylesheet.systemPalette.windowText
      palette.base: Stylesheet.menuBaseColor
      palette.text: Stylesheet.textColor

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
