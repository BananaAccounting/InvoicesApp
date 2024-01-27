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

pragma Singleton

import QtQuick
import QtQuick.Controls

Item {
    // Text and margin sizes
    property double pixelScaleRatio: scaleReference.getPixelScaleRatio()
    property int defaultMargin: 10 * pixelScaleRatio

    // Colors
    property double minimumContrast: 4.5
    property color baseColor: systemPalette.base
    property color buttonColor: systemPalette.button
    property color notificationBarColor: isDarkModus() ? "#0C0C0C" : "#DEEEF7" // HEX: #DEEEF7 RGB: 222, 238, 247
    property color textColor: systemPalette.text
    property color linkColor: "blue"
    property color selectionColor: systemPalette.highlight
    property color selectedTextColor: Qt.platform.os === "osx" ? systemPalette.text : systemPalette.highlightedText

    // Reference palette
    property SystemPalette systemPalette: SystemPalette{
        colorGroup: SystemPalette.Active
    }

    Component.onCompleted: {
        updatePalette()
    }

    onBaseColorChanged: {
        updatePalette()
    }

    function isDarkModus() {
        // To find if we are in dark modus, check the contrast ratio between
        // a black text and the window base color
        return getContrastRatio(Qt.rgba(1, 1, 1, 0), systemPalette.base) > 8
    }

    function updatePalette() {
        // Adapt colors to have a nice contrast under dark mode
        let defaultLinkColor = Qt.rgba(0, 0, 255)
        if (getContrastRatio(defaultLinkColor, systemPalette.base) > minimumContrast) {
            linkColor = defaultLinkColor;
        } else {
            linkColor = "lightblue"
        }
    }

    /**
     * https://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
     */
    function colorLuminosity(c) {
        let r = linearRGBValue(c.r);
        let g = linearRGBValue(c.g);
        let b = linearRGBValue(c.b);

        let toReturn = (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
        return toReturn;
    }

    function linearRGBValue(componentValue) {
        let toReturn = componentValue;
        if (toReturn <= 0.03928)
            return toReturn / 12.92;

        toReturn = (toReturn + 0.055) / 1.055;
        return Math.pow(toReturn, 2.4);
    }

    /**
     * https://www.w3.org/TR/WCAG20-TECHS/G17.html#G17-tests
     */
    function getContrastRatio(c1, c2)
    {
        let luminosity1 = 0.05 + colorLuminosity(c1);
        let luminosity2 = 0.05 + colorLuminosity(c2);
        let l1 = c1.hslLightness
        let l2 = c2.hslLightness
        if (luminosity1 < luminosity2)
            return luminosity2 / luminosity1;
        else
            return luminosity1 / luminosity2;
    }

    /**
     * This TextField is used to calculate the scale factor
     * for pixel lenghts on hdpi displays.
     * The hight reference for a TextField is 24.
     */
    TextField {
        id: scaleReference
        function getPixelScaleRatio() {
            return height / 24;
        }
    }
}


