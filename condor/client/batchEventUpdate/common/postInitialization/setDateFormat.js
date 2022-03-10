var postInitialization = function(my, dateFormatting) {
    my.setDateFormat = function() {

        dateFormatting.setInternationalizationUrl(utilities.appBaseUrl('batchEventUpdate/externaldependency/datejs/build/production/i18n/'));
        ko.postbox.subscribe('applicationDetail', function(applicationDetail) {
            if (applicationDetail && applicationDetail.currentUser && applicationDetail.currentUser.preferences) {
                dateFormatting.setLanguage(applicationDetail.currentUser.preferences.Culture, applicationDetail.currentUser.preferences.DateFormat);
            }
        });
    };

    return my;
}(postInitialization || {}, dateFormatting);