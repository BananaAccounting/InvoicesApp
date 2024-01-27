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
import QtQuick.Window
import QtQuick.Controls

import "./components"

SimpleMessageDialog {
    id: messaggeDialog
    visible: false

    text: getPixelMetrics()

    function getPixelMetrics() {
        let text = "Display info" + "\n"
        text += "Version: " + Banana.script.getParamValue('pubdate') + "\n"
        text += "Pixel density: " + Screen.pixelDensity + "\n"
        text += "Device pixel ratio: " + Screen.devicePixelRatio + "\n"
        text += "TextField height: " + pixelMetricsTextField.height + "\n"
        text += "Font xHeight: " + pixelMetricsFont.xHeight + "\n"
        text += "Pixel scale ratio: " + Stylesheet.pixelScaleRatio + "\n"
        return text
    }

    TextField {
        id: pixelMetricsTextField
        text: "AÈjJÇ"
        visible: false
    }

    FontMetrics {
        id: pixelMetricsFont
    }

}
