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
    /* Scale factor applied to nearly every pixel length in the dialog.

       On the desktop it is measured from the height of a plain TextField, as it always has
       been. That field is 24 high on macOS, where the nominal sizes were chosen, so the ratio
       is exactly 1 there.

       On iOS and Android it is derived from the system font instead. The height of a
       TextField is decided by the active Qt Quick Controls style, and Material, which Android
       uses, draws a text field far taller than the other styles do: the ratio inflated there,
       and with it every margin, height and minimum width in the dialog. The font does not
       change with the control style.

       The font based ratio is not used on the desktop as well, because it cannot come out at
       exactly 1 there: on macOS the text is 15.296875 high, against the 15.3 reference, and
       lengths stored in int properties are truncated, not rounded - defaultMargin became 9
       instead of 10. On Windows and Linux it would differ from the ratio the desktop dialog
       has always been drawn with.

       referenceTextHeight is the text height on the display the nominal sizes were chosen on
       (macOS, default system font). Both ratios are shown by the diagnostics dialog, opened
       with Ctrl+Alt+9. */
    readonly property double referenceTextHeight: 15.3
    readonly property double styleDependentRatio: scaleReference.height / 24
    readonly property double fontBasedRatio: Math.max(referenceMetrics.height, 1) / referenceTextHeight
    property double pixelScaleRatio: Qt.platform.os === "ios" || Qt.platform.os === "android" ?
                                         fontBasedRatio : styleDependentRatio

    property int defaultMargin: 10 * pixelScaleRatio

    /* Spacing scale. Nearly everything used the same ten points, so a field stood as far from
       the next field as a section stood from the next section, and nothing read as grouped.
       Four points inside a group of fields, eight between the parts of one line, sixteen
       between sections - so the eye sees the groups before it reads the labels. */
    readonly property int spacingTight: 4 * pixelScaleRatio
    readonly property int spacingBase: 8 * pixelScaleRatio
    readonly property int spacingSection: 16 * pixelScaleRatio

    /* The colour of a label that names a field. A label is read once, to find the field; the
       value is what is read afterwards, every time. Keeping both at full strength made every
       form a wall of equal text. Taken from the theme's own text colour, so it follows the
       system in both modes: see mutedTextColor below. */
    readonly property color labelColor: mutedTextColor

    /* Headings: the dialog's font, a tenth larger and semi bold. Derived from the font the
       dialog is drawn with rather than from a fixed size, so it follows the system font like
       everything else. A font carries its size either in points or in pixels, never both, and
       which one it is depends on the platform: the unset one reads as -1, so each case is
       handled. */
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
    // Fainter than borderColor on purpose. It divides sections of a form, which is
    // structure rather than content, and it must not be mistaken for the rule above a
    // total - that one means "these figures add up to the number below" and has to stay
    // the stronger of the two. Here the separating is done by the space around the line.
    property color separatorColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.18)

    // Tinted surface for status banners. Derived from the accent rather than from the
    // text colour, so it stays clearly distinct from buttonColor (the tab bar) instead
    // of blending into it, and follows the theme on its own.
    property color accentSurfaceColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.14)

    // Surface of the menus. The desktop styles draw a menu from the palette role window (base
    // for Fusion), and handing them the dialog's own colours made a menu in dark mode the same
    // colour as the dialog under it: it did not stand out, and its border, derived from the
    // same colour, vanished too. A dark interface lifts a popup by drawing it lighter than
    // what lies beneath, so a little of the text colour is mixed in. Opaque, unlike the
    // neutral tokens above, as a menu must not show what is behind it. The light theme keeps
    // the system colours, exactly as before.
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


