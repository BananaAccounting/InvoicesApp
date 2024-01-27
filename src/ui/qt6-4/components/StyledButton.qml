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

Button {
   id: button
   scale: state === "Pressed" ? 0.98 : 1.0

   leftPadding: Stylesheet.defaultMargin
   rightPadding: Stylesheet.defaultMargin

   Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

   contentItem: Label {
      id: labelId
      text: button.text
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      color: button.enabled ? Stylesheet.textColor : "gray"
   }

   states: [State {
      name: "Hovering"
         PropertyChanges {
            target: background
            color: "#e6e6e6"
         }
      },
   State {
      name: "Pressed"
      PropertyChanges {
         target: background
         color: "#e6e6e6"
         border.color: "white"
      }
   }]

   transitions: [
       Transition {
           from: ""; to: "Hovering"
           ColorAnimation {
               duration: 300
               easing.type: Easing.InOutQuad
           }
       },
       Transition {
           from: "*"; to: "Pressed"
           ColorAnimation {
               duration: 40
               easing.type: Easing.InOutQuad
           }
       }
   ]

   background: Rectangle {
      color: Stylesheet.buttonColor
      implicitHeight: 34 * Stylesheet.pixelScaleRatio
      // implicitWidth: contentItem.Width
      radius: 2.0 * Stylesheet.pixelScaleRatio
      border.width: 1
      border.color: "#e6e6e6"
   }

   MouseArea {
        hoverEnabled: true
        anchors.fill: button
        onEntered: { button.state='Hovering'}
        onExited: { button.state=''}
        onPressed: { button.state='Pressed'}
        onClicked: { button.clicked();}
        onReleased: {
            if (containsMouse)
              button.state="Hovering";
            else
              button.state="";
        }
    }
}
