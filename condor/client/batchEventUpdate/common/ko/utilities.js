var utilities = (function(my) {
    'use strict';

    my.appBaseUrl = function(path) {
        return '../' + path;
    };

    my.api = function(path) {
        return '../' + 'api/' + path;
    };

    var userDateFormat = 'dd-MMM-yyyy';

    var readDate = function(source) {
        var v = ko.utils.unwrapObservable(source);

        var d = parseDate(v);
        if (d) {
            return d.toString(userDateFormat);
        }

        return null;
    };

    var writeDate = function(value) {
        var v = ko.utils.unwrapObservable(value);

        var d = parseDate(v);
        if (d) {
            return d.toString(userDateFormat);
        }

        return null;
    };

    var parseDate = function(v) {
        if (!v || v.trim === '') {
            return null;
        }

        var parsedDate = Date.parse(v);
        if (parsedDate) {
            return parsedDate;
        }

        var userDateFormatInUpperCase = userDateFormat.toUpperCase();
        var parsedMoment = moment(v, userDateFormatInUpperCase);
        if (parsedMoment && parsedMoment.isValid()) {
            return parsedMoment.toDate();
        }
       
        var parsedMoment = moment(v, userDateFormatInUpperCase, 'en');        
        if (parsedMoment && parsedMoment.isValid()) {            
            return parsedMoment.toDate();
        }

        return null;
    }


    my.observableDate = function(date, writeCallback) {
        var f = ko.isObservable(date) ? date : ko.observable(date);
        var u = ko.observable(false);

        return ko.computed({
            read: function() {
                u();
                return readDate(f);
            },
            write: function(value) {
                var d = writeDate(value);
                if (d === value && value === writeDate(f())) {
                    return;
                }

                f(d);
                u(!u());

                if (writeCallback) {
                    writeCallback(d);
                }
            }
        });
    };

    my.toISODateString = function(date) {
        var dateString = ko.isObservable(date) ? ko.utils.unwrapObservable(date) : date;
        if (dateString && dateString.trim() !== '') {
            var parsedDate = parseDate(dateString);
            if (parsedDate) {
                return parsedDate.toString('yyyy-MM-dd');
            }
        }

        return null;
    }

    ko.postbox.subscribe('applicationDetail', function(applicationDetail) {
        if (applicationDetail && applicationDetail.currentUser && applicationDetail.currentUser.preferences) {
            userDateFormat = applicationDetail.currentUser.preferences.DateFormat;
        }
    });

    return my;
})(utilities || {});