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
    /* Scale factor applied to nearly every pixel length in the dialog. On the desktop it is
       measured from a plain TextField, 24 high on macOS where the sizes were chosen, so the
       ratio is exactly 1 there. On iOS and Android it comes from the system font instead:
       Material draws a text field far taller, which inflated every length on Android.

       Not font based on the desktop as well, because it cannot come out at exactly 1 there:
       int properties truncate, and defaultMargin became 9 instead of 10. Both ratios are
       shown by the diagnostics dialog, Ctrl+Alt+9. */
    readonly property double referenceTextHeight: 15.3
    readonly property double styleDependentRatio: scaleReference.height / 24
    readonly property double fontBasedRatio: Math.max(referenceMetrics.height, 1) / referenceTextHeight
    property double pixelScaleRatio: Qt.platform.os === "ios" || Qt.platform.os === "android" ?
                                         fontBasedRatio : styleDependentRatio

    property int defaultMargin: 10 * pixelScaleRatio

    /* Spacing scale. Everything used the same ten points, so nothing read as grouped: four
       inside a group of fields, eight between the parts of one line, sixteen between
       sections. */
    readonly property int spacingTight: 4 * pixelScaleRatio
    readonly property int spacingBase: 8 * pixelScaleRatio
    readonly property int spacingSection: 16 * pixelScaleRatio

    /* The colour of a label that names a field: read once to find the field, while the value
       beside it is read every time. Both at full strength made a wall of equal text. */
    readonly property color labelColor: mutedTextColor

    /* Headings: the dialog's own font, a tenth larger and semi bold, so it follows the system
       font. A font carries its size in points or in pixels, never both, and which one depends
       on the platform: the unset one reads as -1, so both cases are handled. */
    readonly property font sectionTitleFont: referenceMetrics.font.pointSize > 0 ?
                                                 Qt.font({ family: referenceMetrics.font.family,
                                                           weight: Font.DemiBold,
                                                           pointSize: referenceMetrics.font.pointSize * 1.1 }) :
                                                 Qt.font({ family: referenceMetrics.font.family,
                                                           weight: Font.DemiBold,
                                                           pixelSize: Math.round(referenceMetrics.font.pixelSize * 1.1) })

    // Corner radius, shared so controls read as one consistent, modern style
    property double cornerRadius: 6 * pixelScaleRatio
    property double cornerRadiusSmall: 3 * pixelScaleRatio

    // Colors
    property double minimumContrast: 4.5
    property color baseColor: systemPalette.base
    property color buttonColor: systemPalette.button
    // Unused since the version notification bar was removed from DlgInvoice. Status
    // banners now use accentSurfaceColor below. Kept commented in case it is needed again.
    // property color notificationBarColor: isDarkModus() ? "#0C0C0C" : "#DEEEF7" // HEX: #DEEEF7 RGB: 222, 238, 247
    property color textColor: systemPalette.text
    property color linkColor: "blue"
    property color selectionColor: systemPalette.highlight
    property color selectedTextColor: Qt.platform.os === "osx" ? systemPalette.text : systemPalette.highlightedText

    // Banana brand blue, used for primary actions and selected/active states.
    // Automatically brightened in dark mode if the plain brand color wouldn't
    // have enough contrast against the window background.
    property color bananaBlue: "#354894"
    property color accentColor: getContrastRatio(bananaBlue, systemPalette.base) > minimumContrast ?
                                     bananaBlue : Qt.lighter(bananaBlue, 1.6)
    property color accentColorHover: Qt.lighter(accentColor, 1.12)
    property color accentColorPressed: Qt.darker(accentColor, 1.12)
    property color accentTextColor: "white"

    // Neutral tokens derived from the theme's own text color, so borders/hover
    // states/muted text stay correct in both light and dark mode automatically.
    property color borderColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.3)
    property color borderColorStrong: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.45)
    property color hoverColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.1)
    property color pressedColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.12)
    property color mutedTextColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.55)
    // Fainter than borderColor on purpose: it divides sections, which is structure, and must
    // not be mistaken for the rule above a total. Here the space around the line separates.
    property color separatorColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.18)

    // Tinted surface for status banners. Derived from the accent rather than from the
    // text colour, so it stays clearly distinct from buttonColor (the tab bar) instead
    // of blending into it, and follows the theme on its own.
    property color accentSurfaceColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.14)

    // Surface of the menus. In dark mode the dialog's own colours made a menu the same colour
    // as the dialog under it, border included, so a little text colour is mixed in to lift it.
    // Opaque, unlike the tokens above. The light theme keeps the system colours.
    property color menuWindowColor: isDarkModus() ?
                                        Qt.tint(systemPalette.window, Qt.rgba(textColor.r, textColor.g, textColor.b, 0.12)) :
                                        systemPalette.window
    property color menuBaseColor: isDarkModus() ? menuWindowColor : baseColor

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
     * Metrics of the system font, the basis of the scale factor on iOS and Android.
     */
    FontMetrics {
        id: referenceMetrics
    }

    /**
     * A plain TextField, the basis of the scale factor on the desktop.
     * Its height reference is 24.
     */
    TextField {
        id: scaleReference
    }
}


