angular.module('inprotech.components.form')
    .service('dateService', function($rootScope, dateParserService, $locale) {
        'use strict';

        var culture = 'en';
        var dateFormat = 'dd-MMM-yyyy';
        var user = $rootScope.appContext.user;

        if (user) {
            culture = user.preferences.culture;
            dateFormat = user.preferences.dateFormat;
        }

        culture = culture || $rootScope.appContext.userAgent.languages[0];

        if (!dateFormat || dateFormat === 'd' || culture.indexOf('zh') === 0) {
            dateFormat = 'shortDate';
        }

        function buildParseFormats(dateFormat) {
            var a = dateFormat.replace(/\bd{1}\b/, 'dd').replace(/\bM{1,2}\b/, 'MMM').replace(/\by{1,2}\b/, 'yyyy');

            var b = a.replace('MMM', 'M!').replace('dd', 'd!');
            var c = a.replace('yyyy', 'yy');
            var d = b.replace('yyyy', 'yy');
            var e = a.replace('dd', 'd!');
            var f = e.replace('yyyy', 'yy');

            var formats = [];
            var all = [a, b, c, d, e, f];
            var delimiters = [' ', '.', '/', '-', ''];

            all.forEach(function(format) {
                formats.push(format);
                delimiters.forEach(function(delimiter) {
                    formats.push(format.split('-').join(delimiter));
                });
            });

            formats.push('yyyy-MM-dd');
            formats.push('shortDate');
            formats.push('longDate');

            _.chain(formats)
                .filter(function(f) {
                    return f.indexOf('MMM') != -1;
                })
                .each(setParserFormat);
            setParserFormatForShortDate();

            return _.unique(formats);
        }

        function setParserFormat(format) {
            var delimiters = [' ', '.', '/', '-'];

            var separator = _.find(delimiters, function(d) {
                return format.indexOf(d) != -1;
            }) || '';

            dateParserService.setParserFormat(format, separator);
        }

        function setParserFormatForShortDate() {
            var shortDateFormat = $locale.DATETIME_FORMATS['shortDate'];
            if (shortDateFormat && shortDateFormat.indexOf('MMM') != -1) {
                setParserFormat(shortDateFormat);
            }
        }

        //This code is specifically added for DEST start dates in countries that have positive timezone offset like AEST
        function adjustTimezoneOffsetDiff(date) {
            var currentTimezoneoffset = date.getTimezoneOffset();

            if (currentTimezoneoffset > 0) {
                return date;
            }

            var day = date.getDate();
            var month = date.getMonth() + 1;
            var dateString = date.getFullYear() + ' ' + (month < 10 ? '0' + month : month) + ' ' + (day < 10 ? '0' + day : day);
            var timezoneOffsetAtStartofDay = moment(dateString, 'YYYY MM DD').toDate().getTimezoneOffset();

            if (currentTimezoneoffset !== timezoneOffsetAtStartofDay) {
                var diff = timezoneOffsetAtStartofDay - currentTimezoneoffset;
                return moment(date).add(diff, 'minutes').toDate();
            }

            return date;
        }

        return {
            culture: culture,
            dateFormat: dateFormat,
            useDefault: function() {
                return culture.indexOf('zh') === 0 || dateFormat === 'shortDate';
            },
            getParseFormats: function() {
                return buildParseFormats(dateFormat);
            },
            getExpandedParseFormats: function() {
                var parseFormats = buildParseFormats(dateFormat);
                if (dateFormat == 'shortDate') {
                    var parseFormatForShortDate = $locale.DATETIME_FORMATS['shortDate'];

                    return _.unique(parseFormats.concat(buildParseFormats(parseFormatForShortDate)).concat([parseFormatForShortDate]));
                }

                return parseFormats;
            },
            format: function(val) {
                var value = val instanceof Date ? new Date(val.getTime() + val.getTimezoneOffset() * 60 * 1000) : val
                if (dateFormat === 'shortDate') {
                    return moment(value).format($locale.DATETIME_FORMATS['shortDate'].toUpperCase());
                }

                return moment(value).format(dateFormat.toUpperCase());
            },
            adjustTimezoneOffsetDiff: adjustTimezoneOffsetDiff,
            shortDateFormat: $locale.DATETIME_FORMATS['shortDate']
        };
    });
