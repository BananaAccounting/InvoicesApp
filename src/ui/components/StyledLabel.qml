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

import QtQuick.Controls

/**
 * The StyledLabel component update the text color on the fly
 * when the operating system switch from normal mode to dark mode.
 */
Label {
    // The colour of a label naming a field: quieter than the value beside it, see
    // Stylesheet.labelColor. Where a label carries a heading or a figure instead, the
    // colour is set on the spot - the read only banner, the totals, the table headings.
    color: Stylesheet.labelColor

    /* And the size of one: a step below the value it names, so that a form reads as values
       with names attached rather than as one even block of text. A label that is really a
       heading or a figure sets a font of its own - see Stylesheet's type scale. */
    font: Stylesheet.labelFont
}
