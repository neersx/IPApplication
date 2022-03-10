$(function () {
    'use strict';
    var statisticsConsented = window.localStorage.getItem('statisticsConsented');
    var firmConsentedToUserStatistics = window.localStorage.getItem('firmConsentedToUserStatistics');
    var options = {
        applicationName: 'inprotech',
        key: null,
        autoPageViewTracking: false,
        autoStateChangeTracking: false,
        autoLogTracking: false,
        autoExceptionTracking: false,
        sessionInactivityTimeout: 120000,
        developerMode: false
    };

    if (statisticsConsented) {
        var appInsightSettingsData = window.localStorage.getItem('appInsightsSettings');
        if (appInsightSettingsData && appInsightSettingsData !== 'NOT_AVAILABLE') {
            var appInsightSettings = JSON.parse(appInsightSettingsData);
            options.key = appInsightSettings.key;
            options.autoPageViewTracking = appInsightSettings.sessionTracking;
            options.autoStateChangeTracking = appInsightSettings.sessionTracking;
            options.autoExceptionTracking = appInsightSettings.exceptionTracking;
        }
    }
    if (firmConsentedToUserStatistics && statisticsConsented) {
        if (window.inproInitGtag) {
            inproInitGtag();
            inproInitGtag = undefined;
        }
    }
    var tempStorageId = utils.url.params().tempstorageid;
    var app = batchEventUpdate.appViewModel(tempStorageId);
    ko.applyBindings(app);
});