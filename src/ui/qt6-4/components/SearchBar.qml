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

RowLayout {
   id: control
   property var textControl: null

   signal done()
   signal notFound()

   StyledTextField {
      id: findTextField
      text: ""
      Layout.fillWidth: true
      Keys.onPressed: {
         if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            searchNext()
            event.accepted = true;
         } else if (event.key === Qt.Key_Escape) {
            control.visible = false
            done()
            event.accepted = true;
         }
      }
   }

   StyledButton {
      text: qsTr("Previous")
      onClicked: searchPrevious()
      Shortcut {
         sequence: StandardKey.FindPrevious
         onActivated: searchPrevious()
      }

   }

   StyledButton {
      text: qsTr("Next")
      onClicked: searchNext()
      Shortcut {
         sequence: StandardKey.FindNext
         onActivated: searchNext()
      }
   }

   StyledButton {
      text: qsTr("Done")
      onClicked: {
         control.visible = false
         done()
      }
   }

   onVisibleChanged: {
      if (visible)
         findTextField.focus = true
   }

   function searchNext() {
      if (!textControl || !textControl.length || !findTextField.length) {
         notFound()
         return
      }

      var text = textControl.text.toLowerCase();
      var findText = findTextField.text.toLowerCase();

      var startPosition = textControl.cursorPosition
      if (startPosition < 0 || startPosition >= text.length)
         startPosition = 0

      var nextPosition = text.indexOf(findText, startPosition)
      if (nextPosition >= 0) {
         textControl.select(nextPosition, nextPosition + findText.length)
         return true;
      }

      if (startPosition === 0) {
         notFound()
         return false;
      }

      nextPosition = text.indexOf(findText)
      if (nextPosition >= 0) {
         textControl.select(nextPosition, nextPosition + findText.length)
         return true;
      }

      notFound()
      return false;
   }

   function searchPrevious() {
      if (!textControl || !textControl.length || !findTextField.length) {
         notFound()
         return
      }

      var text = textControl.text.toLowerCase();
      var findText = findTextField.text.toLowerCase();

      var startPosition = textControl.cursorPosition - findText.length - 1
      if (startPosition < 0 || startPosition > text.length)
         startPosition = text.length

      var nextPosition = text.lastIndexOf(findText, startPosition)
      if (nextPosition >= 0) {
         textControl.select(nextPosition, nextPosition + findText.length)
         return true;
      }

      if (startPosition === text.length) {
         notFound()
         return false;
      }

      nextPosition = text.lastIndexOf(findText)
      if (nextPosition >= 0) {
         textControl.select(nextPosition, nextPosition + findText.length)
         return true;
      }

      notFound()
      return false;
   }
}
