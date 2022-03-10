angular.module('inprotech.core').provider('appContext', function($translateProvider) {
    'use strict';

    this.$get = function($rootScope, $http, $q, $translate, tmhDynamicLocale) {
        var appCtx, promises = [];
        promises.push(load('en'));

        promises.push($http.get('api/enrichment')
            .then(function(response) {
                var data = response.data;
                appCtx = {
                    user: data.intendedFor,
                    userAgent: data.userAgent,
                    systemInfo: data.systemInfo,
                    programs: data.programs,
                    isWindowsAuthOnly: data.isWindowsAuthOnly,
                    gaKey: (data.gaSettings || {}).key
                };

                if (!appCtx.user.preferences.culture) {
                    appCtx.user.preferences.culture = 'en';
                }

                var culture = appCtx.user.preferences.culture;
                var resourcePaths = appCtx.user.preferences.resources || [];

                var rloader = [];
                if (culture !== 'en') {
                    if (culture && culture.length >= 5) {
                        rloader.push(tmhDynamicLocale.set(culture));
                    }

                    _.each(resourcePaths, function(rp) {
                        if (!rp.code) return;
                        rloader.push(load(rp.code, rp.path));
                    });

                    return $q.all(rloader);
                }

                return $q.resolve();
            }));

        return $q.all(promises).then(function() {
            var culture = appCtx.user.preferences.culture;
            var fallback = [culture];

            if (culture && culture.length >= 5) {
                fallback.push(culture.substr(0, 2));
            }

            if (_.indexOf(fallback, 'en') === -1) {
                fallback.push('en');
            }
            $translate.fallbackLanguage(fallback);
            $translate.use(culture);
            $rootScope.appContext = appCtx;

            return $rootScope.appContext;
        });

        function load(culture, resourcePath) {
            var r = resourcePath || 'condor/localisation/translations/translations_' + culture + '.json';
            return $http.get(r + '?revalidate=yes', {
                handlesError: ignoreNotFound
            })
                .then(function(response) {
                    $translateProvider.translations(culture, init(response.data));
                }).catch(angular.noop);
        }

        function init(obj) {
            _.each(obj, function(value, key) {
                if (value == null) {
                    obj[key] = key;
                } else if (_.isObject(value)) {
                    init(value);
                }
            });

            return obj;
        }

        function ignoreNotFound(error, status) {
            return status === 404;
        }
    };
});