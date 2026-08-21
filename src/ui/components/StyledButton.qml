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

   // A primary button uses the banana blue accent, for the main action of a dialog (e.g. Save).
   property bool primary: false

   // Disabled buttons always fall back to the plain neutral look, primary or not:
   // a disabled accent-colored button reads as "active but oddly colored", not "off".
   readonly property bool showAsPrimary: primary && enabled

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
      font.bold: button.showAsPrimary
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      color: !button.enabled ? Stylesheet.mutedTextColor :
                 button.showAsPrimary ? Stylesheet.accentTextColor : Stylesheet.textColor
   }

   states: [State {
      name: "Hovering"
         PropertyChanges {
            target: background
            color: button.showAsPrimary ? Stylesheet.accentColorHover : Stylesheet.hoverColor
         }
      },
   State {
      name: "Pressed"
      PropertyChanges {
         target: background
         color: button.showAsPrimary ? Stylesheet.accentColorPressed : Stylesheet.pressedColor
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
      color: button.showAsPrimary ? Stylesheet.accentColor : Stylesheet.buttonColor
      implicitHeight: 34 * Stylesheet.pixelScaleRatio
      // implicitWidth: contentItem.Width
      radius: Stylesheet.cornerRadius
      border.width: button.showAsPrimary ? 0 : 1
      border.color: Stylesheet.borderColor
   }

   MouseArea {
        enabled: button.enabled
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
