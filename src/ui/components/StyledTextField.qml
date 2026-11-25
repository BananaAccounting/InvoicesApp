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
   implicitHeight: Stylesheet.fieldHeight

   selectByMouse: true
   property bool selected: false
   property bool borderless: false
   property bool modified: false

   /* A cell of a table rather than a field of a form. The rows of a table are told apart by
      their colour, so a cell carries the colour of its row and no frame of its own; the
      frame appears on the cell under the pointer and on the one being edited, which is the
      only place it says anything. */
   property bool cellMode: false
   property color cellBackground: "transparent"

   /* A field inside a card, where the card has a tint of its own: the field takes the
      colour of the page and reads as cut into the card, so it needs no frame to say that
      it can be typed into. The frame is then free to say what it alone can say - which
      field is being edited.

      Only inside a card. A field on the page is the same colour as the page, so there it
      is the frame that makes it a field at all. */
   property bool filled: false

   // True while the field is the one the keyboard or the pointer is on. "selected" is the
   // current cell of the items table, which keeps the keyboard on itself and sends what is
   // typed to that cell: marked like a focused field, because that is what it behaves like.
   // Whoever sets it has to clear it when the keyboard goes elsewhere, or a cell is left
   // looking as though it were still being edited.
   readonly property bool edited: activeFocus || selected
   readonly property bool pointedAt: edited || hovered

   color: Stylesheet.textColor
   selectionColor : Stylesheet.selectionColor
   selectedTextColor: Stylesheet.selectedTextColor

   background: Rectangle {
      color: borderless ? "transparent" :
                 textField.cellMode ? (textField.pointedAt ? Stylesheet.baseColor
                                                           : textField.cellBackground)
                                    : Stylesheet.baseColor

      border.color: textField.edited ? Stylesheet.accentColor :
                        borderless ? "transparent" :
                            (textField.cellMode || textField.filled) ?
                                (textField.hovered ? Stylesheet.borderColor : "transparent") :
                                Stylesheet.borderColor
      border.width: textField.activeFocus || textField.selected ? 2 : 1
      radius: Stylesheet.cornerRadiusSmall

      Behavior on border.color {
          ColorAnimation { duration: 120 }
      }
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
       modified = true
   }

   onTextEdited: function() {
       /**
         Questa segnale viene chiamato solamente se nella colonna della
         quantità vengono inseriti almeno 2 caratteri, con un solo carattere
         il segnale non viene chiamato, non sappiamo esattamente perchè, ma di conseguenza
         il valore inserito non viene salvato nel modello dei dati e quindi la quantitâ
         durante il ricacolo della fattura, risulta vuota.

         Per ora la soluzione che stiamo testando e la forzatura dell'aggiornamento della veriabile "modified"
         a true, nel segnale sopra "onEditingFinished", modifica da testare.
*/
       //Banana.console.debug("onTextEdited");
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

      // On the desktop the style draws the menu from its palette, which stays light in dark
      // mode: the dialog's own colours are handed to it, as for the menus in DlgInvoice.qml.
      palette.window: Stylesheet.menuWindowColor
      palette.windowText: Stylesheet.systemPalette.windowText
      palette.base: Stylesheet.menuBaseColor
      palette.text: Stylesheet.textColor

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
