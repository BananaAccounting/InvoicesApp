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
    /* One step behind the value it names, not two: at a little over half opacity a form
       full of labels came out washed on anything but a perfect screen. The grey of what is
       genuinely secondary stays where it was, further down. */
    readonly property color labelColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.68)

    /* The type scale. Everything used to be the system font at one single size, told apart
       only by colour and weight, so a form read as one even block: the name of a field, its
       value and the heading above them all looked alike. Four steps are enough here - a
       caption, the body, a heading, and the one figure the document is about.

       All of them follow the system font. A font carries its size in points or in pixels,
       never both, and which one depends on the platform: the unset one reads as -1, so both
       cases are handled in one place.  */
    function scaledFont(factor, weight) {
        if (referenceMetrics.font.pointSize > 0) {
            return Qt.font({ family: referenceMetrics.font.family,
                             weight: weight,
                             pointSize: referenceMetrics.font.pointSize * factor })
        }
        return Qt.font({ family: referenceMetrics.font.family,
                         weight: weight,
                         pixelSize: Math.round(referenceMetrics.font.pixelSize * factor) })
    }

    // The name of a field, a caption, a unit: read once to find the value beside it.
    readonly property font labelFont: scaledFont(0.92, Font.Normal)

    // A sentence meant to be read: a notice, a message. The size of the values of the form.
    readonly property font bodyFont: scaledFont(1.0, Font.Normal)

    // Headings of the sections of a page.
    readonly property font sectionTitleFont: scaledFont(1.1, Font.DemiBold)

    // The title of a card: a step below a section heading, a step above the body.
    readonly property font cardTitleFont: scaledFont(1.02, Font.DemiBold)

    // The name of the open document, in the bar at the top of the window.
    readonly property font documentTitleFont: scaledFont(1.2, Font.DemiBold)

    // The total: the one figure the whole document is about.
    readonly property font totalFont: scaledFont(1.3, Font.DemiBold)

    // Corner radius, shared so controls read as one consistent, modern style
    property double cornerRadius: 6 * pixelScaleRatio
    property double cornerRadiusSmall: 3 * pixelScaleRatio

    /* The height of a field and of a button. Fields used to be 28 points, which left the
       text pressed against the frame and made a form of them look cramped next to buttons
       six points taller. */
    property int fieldHeight: 30 * pixelScaleRatio
    property int controlHeight: 34 * pixelScaleRatio

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
    // text colour, so it stays clearly distinct from the page instead of blending into
    // it, and follows the theme on its own.
    property color accentSurfaceColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)

    /* The surfaces of the window. Mixed from the text colour rather than taken from the
       system palette: a translucent tint lands the same way in a light and in a dark theme,
       while systemPalette.button came out almost the colour of the page on one platform and
       far from it on another.

       Two levels, and only two. There used to be four greys a shade apart - the bars, the
       cards, the heading row of the items table - none of which said anything the others
       did not, and one of them from another family altogether. Now one grey means "a group
       of fields", and the bars are the page with a rule under them, which is all a bar
       needs to be a bar.

       The card has to be far enough from the page to be seen, because the fields inside it
       take the colour of the page and are told apart from it by that difference alone. */
    property color surfaceColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.06)
    property color barColor: baseColor

    /* The same grey, mixed down onto the page so that it covers instead of letting through.
       The heading row of the items table needs this: its cells are laid out again whenever
       the width of the Description column is worked out, and the cells the view leaves
       behind stay where they were. An opaque cell paints over them, a translucent one shows
       every one of them - the titles of the columns that move came out written twice. */
    property color surfaceColorOpaque: Qt.tint(baseColor, surfaceColor)

    /* Every other row of the items table. The rows are told apart by this and not by a
       frame around each cell: a table of figures is read down its columns, and a frame
       around every one of them cut those columns into boxes. Faint on purpose - it has to
       be felt rather than seen, or it competes with the figures it carries. */
    property color rowAlternateColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.06)

    /* Something that wants attention without being wrong: a document with changes that are
       not saved yet. Brightened in dark mode like the accent above, for the same reason. */
    property color amberColor: "#B5730C"
    property color warningColor: getContrastRatio(amberColor, systemPalette.base) > minimumContrast ?
                                     amberColor : Qt.lighter(amberColor, 1.7)
    property color warningSurfaceColor: Qt.rgba(warningColor.r, warningColor.g, warningColor.b, 0.16)

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


