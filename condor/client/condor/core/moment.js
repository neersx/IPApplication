angular.module('inprotech.core')
    .filter('moment', ['$rootScope',
        function($rootScope) {
            'use strict';
            return function(input, requestedFormat) {
                if (!input) {
                    return '';
                }
                var culture, dateFormat;
                var user = $rootScope.appContext.user;

                var m = input.input && input.inputFormat ?
                            moment(input.input, input.inputFormat) :
                            moment(input);

                if (user) {
                    culture = user.preferences.culture;
                    dateFormat = user.preferences.dateFormat;
                }

                culture = culture || $rootScope.appContext.userAgent.languages[0];
                if (culture) {
                    m = m.locale(culture);
                }

                if (!dateFormat || dateFormat === 'd') {
                    dateFormat = 'll';
                } else {
                    dateFormat = dateFormat.toUpperCase();
                }

                if (requestedFormat) {
                    dateFormat = requestedFormat;
                }

                return m.format(dateFormat);
            };
        }
    ]);
