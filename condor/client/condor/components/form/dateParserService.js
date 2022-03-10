angular.module('inprotech.components.form')
    .service('dateParserService', function(uibDateParser, $locale) {
        'use strict';
        /* https://github.com/angular-ui/bootstrap/issues/4241 */

        var formatsAlreadySet = [];

        function setParserFormat(format, separator) {
            if (_.indexOf(formatsAlreadySet, format) != -1) {
                return;
            }
            // Triggers creation of the parser
            uibDateParser.parse('01-Jan-1990', format);
            var formatToUse = format.split('.').join('\\.');

            // Override parser to handle lower cases
            var parser = uibDateParser.parsers[formatToUse],
                regex = '(' + [
                    transformerMapMatcher(parser.map[0]),
                    transformerMapMatcher(parser.map[1]),
                    transformerMapMatcher(parser.map[2])
                ].join(')' + separator + '(') + ')';

            parser.regex = new RegExp('^' + regex + '$');

            formatsAlreadySet.push(format);
        }

        function transformerMapMatcher(map) {
            if (map.key != 'MMM') {
                return map.matcher;
            }

            var matcher = map.matcher.split('|').map(function(value) {
                var regex = '';
                angular.forEach(value, function(letter) {
                    regex += '[' + letter.toLocaleUpperCase() + letter.toLocaleLowerCase() + ']';
                });
                return regex;
            }).join('|');

            var apply = map.apply;
            map.apply = function(value) {
                apply.call(this, getCorrectMonthString(value));
            };

            return matcher;
        }

        function getCorrectMonthString(value) {
            return _.find($locale.DATETIME_FORMATS.SHORTMONTH, function(m) {
                if (new RegExp(m, 'i').test(value)) {
                    return m;
                }
            });
        }

        return {
            setParserFormat: setParserFormat
        };
    });
