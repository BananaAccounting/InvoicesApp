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

import "../base/settings.js" as Settings

QtObject {
    // Constants
    readonly property string settings_id: "invoices"

    readonly property string view_id_base: "base"
    readonly property string view_id_short: "short"
    readonly property string view_id_long: "long"
    readonly property string view_id_full: "full"

    readonly property var default_views_titles: {
        "base": qsTr("Base"),
        "short": qsTr("Custom 1"),
        "long": qsTr("Custom 2"),
        "full": qsTr("Complete")
    }

    // Current settings data

    property bool modified: false
    property bool loaded: false
    property var data: Settings.getDefaultSettings()

    // Signals
    // Some are made available as signal and as counter
    // Use one of them and not both, if not you well get a double notifications
    // N.B.: Counters are used as signals in qml binding

    signal fieldsVisibilityChanged

    property int signalViewsSettingsChanged: 1
    property int signalFieldsVisibilityChanged: 1
    property int signalItemsVisibilityChanged: 1
    property int signalTranslationsChanged: 1
    property int signalNotificationsChanged: 1

    // Other properties
    property DevSettings devSettings: null

    // Settings methods

    function saveSettings() {
        Settings.saveSettings(data)
        modified = false
    }

    function clearSettings() {
        data = Settings.getDefaultSettings()
        modified = true
        signalViewsSettingsChanged++
        signalFieldsVisibilityChanged++
        fieldsVisibilityChanged()
    }

    function loadSettings() {
        data = Settings.getSettings()
        modified = true
        loaded = true
        signalViewsSettingsChanged++
        signalFieldsVisibilityChanged++
        fieldsVisibilityChanged()
    }

    function resetSettings() {
        data = Settings.getDefaultSettings()
        modified = true
        signalViewsSettingsChanged++
        signalFieldsVisibilityChanged++
        fieldsVisibilityChanged()
    }

    function setSettings(newSettings) {
        if (newSettings) {
            data = newSettings
            data = Settings.upgradeSettings(data)
            modified = true
            signalViewsSettingsChanged++
            signalFieldsVisibilityChanged++
            fieldsVisibilityChanged()
        }
    }

    // Fields visibility

    function getInvoiceFieldVisible(fieldId, viewId) {
        if (viewId === view_id_full) {
            return true;
        }
        let viewAppearance = data.interface.invoice.views[viewId].appearance
        if (fieldId in viewAppearance) {
            return viewAppearance[fieldId];
        } else {
            console.log("appearance flag '" + fieldId + "' in view '" + viewId + "' not found")
        }

        return true; // if missing default is visible
    }

    function setInvoiceFieldVisible(fieldId, viewId, value) {
        data.interface.invoice.views[viewId].appearance[fieldId] = value
        signalFieldsVisibilityChanged++
        fieldsVisibilityChanged()
        modified = true
    }

    function meetInvoiceFieldLicenceRequirement(fieldId) {
        if (!fieldId) {
            console.warn("function meetInvoiceFieldLicenceRequirement, parameter 'fieldId' is empty")
        }

        let fieldsRequiringAvancedPlan = getSettingsRequiringAdvancedPlan().appearance;
        if (fieldsRequiringAvancedPlan.indexOf(fieldId) >= 0) {
            if (Banana.application.isInternal && devSettings &&
                    devSettings.disableAdvancedPlanLicense) {
                return false;
            }

            if (!Banana.application.license || Banana.application.license.licenseType !== "advanced") {
                return false
            }
        }
        return true
    }

    // Views titles

    function getDefaultViewTitle(viewid) {
        let viewTitle = default_views_titles[viewid]
        if (viewTitle)
            return viewTitle
        return viewid
    }

    function getSettingsViewTitle(viewid) {
        return data.interface.invoice.views[viewid].title
    }

    function getViewTitle(viewid) {
        if (signalViewsSettingsChanged) {
            let viewTitle = getSettingsViewTitle(viewid)
            if (viewTitle)
                return viewTitle
            return getDefaultViewTitle(viewid)
        }
        return viewid;
    }

    function setViewTitle(viewId, title) {
        data.interface.invoice.views[viewId].title = title.trim()
        modified = true
        signalViewsSettingsChanged++
    }

    // Views visibility

    function isViewVisible(viewId) {
        if (signalViewsSettingsChanged)
            return data.interface.invoice.views[viewId].visible
        return true
    }

    function setViewVisible(viewId, value) {
        data.interface.invoice.views[viewId].visible = value
        modified = true
        signalViewsSettingsChanged++
    }

    // Notifications

    function isNotificationVisible(notificationId) {
        if (signalNotificationsChanged) {
            if (data.interface.notifications && data.interface.notifications[notificationId]) {
                return true
            }
        }
        return false
    }

    function setNotificationVisible(notificationId, value) {
        if (!data.interface.notifications)
            data.interface.notifications = {}
        if (value) {
            data.interface.notifications[notificationId] = true
        } else {
            data.interface.notifications[notificationId] = false
        }
        modified = true
        signalNotificationsChanged++
    }

    // Other methods

    function isInternalVersion() {
        if (Banana.application.isInternal) {
            if (devSettings.disableIsInternalVersionFlag) {
                return false
            }
            return true
        }
        return false
    }


}
