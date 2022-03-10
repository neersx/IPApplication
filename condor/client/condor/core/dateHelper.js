angular.module('inprotech.core').factory('dateHelper', function () {
    'use strict';

    return {
        addDays: function (date, days) {
            if (days === 0) {
                return date;
            }
            return days > 0 ? moment.utc(date).add(days, 'days').toDate() : moment.utc(date).subtract(days * -1, 'days').toDate();
        },
        setTime: function (date, hours, minutes) {
            if (hours == null && minutes == null) {
                return date;
            }
            if (date == null) {
                date = new Date();
            }

            if (hours != null) {
                date = moment.utc(date).set({ h: hours }).toDate();
            }

            if (minutes != null) {
                date = moment.utc(date).set({ m: minutes }).toDate();
            }

            return date;
        },
        getTime: function (date) {
            if (date == null)
                return {
                    hours: 0,
                    minutes: 0
                };
            else {
                var m = moment.utc(date);
                return {
                    hours: m.hours(),
                    minutes: m.minutes()
                };
            }
        },
        convertForDatePicker: function (date) {
            if (date instanceof Object && date.getDate) {
                return date; // date is already a date object
            }

            return date ? moment.utc(date).toDate() : null;
        },
        areDatesEqual: function (date1, date2) {
            return moment(date1).isSame(moment(date2));
        },
        toLocal: function(date) {
            return moment(date).format('YYYY-MM-DD');
        },
        addMonths: function (date, months) {
            if (months === 0) {
                return date;
            }
            return months > 0 ? moment.utc(date).add(months, 'months').toDate() : moment.utc(date).subtract(months * -1, 'months').toDate();
        }
    };
});