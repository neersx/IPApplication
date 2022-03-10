angular.module('inprotechSigninRedirect')
    .controller('redirectController', ['$window', '$location',
        function ($window, $location) {
            'use strict';

            var store = window.localStorage;
            var getObject = function () {
                var value = store['signin'];
                if (value === 'null') {
                    value = null;
                }
                return value ? JSON.parse(value) : {};
            };
            var setObject = function (values) {
                store['signin'] = JSON.stringify(values);
            };

            var localStorage = {
                setItem: function (key, value) {
                    var signinValue = getObject();
                    signinValue[key] = value;
                    setObject(signinValue);
                },
                getItem: function (key) {
                    return getObject()[key];
                }
            }

            var baseUrl = '../../';
            var authModes = {
                forms: 1,
                windows: 2,
                sso: 3,
                adfs: 4
            };

            var redirectUrl = $location.search().goto || baseUrl + '#/home';

            function isSsoAuthMethod() {
                var storedAuthMode = localStorage.getItem('authModeTemp');
                return storedAuthMode && (storedAuthMode === authModes.sso || storedAuthMode === authModes.adfs);
            }

            function clearAuthModeTemp() {
                localStorage.setItem('authModeTemp', null);
            }

            if (isSsoAuthMethod()) {
                localStorage.setItem('authMode', localStorage.getItem('authModeTemp'));
            }

            clearAuthModeTemp();

            $window.location = decodeURIComponent(redirectUrl);
        }
    ]);