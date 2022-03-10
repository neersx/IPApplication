var dateFormatting = function(my, _) {
    'use strict';
    var dateFormat;

    var sanitiseLanguageCode = function(code) {
        // convert the characters after the last '-' to uppercase
        var index = _.lastIndexOf(code, '-');
        if (index === -1) {
            return code;
        }

        var start = index + 1;
        return code.substring(0, start) + code.substring(start).toUpperCase();
    };

    my.setInternationalizationUrl = function(url) {
        Date.Config.i18n = url;
    };

    my.setLanguage = function(culture, dateFormatProvided) {
        dateFormat = dateFormatProvided;
        if (culture) {
            var langCode = sanitiseLanguageCode(culture);
            Date.i18n.setLanguage(langCode, undefined, my.setFormat);
            moment.lang(langCode);
        }
    };

    my.setFormat = function() {
        //Date format if provided in site control- takes precedence over culture date format
        if (dateFormat === 'yyyy-MMM-dd') {
            Date.CultureInfo.dateElementOrder = 'ymd';
            return;
        }
        if (dateFormat === 'MMM-dd-yyyy') {
            Date.CultureInfo.dateElementOrder = 'mdy';
            return;
        }
        if (dateFormat === 'dd-MMM-yyyy') {
            Date.CultureInfo.dateElementOrder = 'dmy';
            return;
        }
    };

    my.configureDateUrlAndLanguage = function(url, culture, dateFormatProvided) {
        my.setInternationalizationUrl(url);
        my.setLanguage(culture, dateFormatProvided);
    };

    return my;
}(dateFormatting || {}, _);