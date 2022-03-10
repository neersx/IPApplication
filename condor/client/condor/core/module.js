angular.module('inprotech.core', [
    'ui.router',
    'ui.router.upgrade',
    'pascalprecht.translate',
    'tmh.dynamicLocale',
    'restmod',
    'cfp.hotkeys',
    'ui.bootstrap',
    'inprotech.core.extensible',
    'ngSanitize',
    'inprotech.downgrades'
]);

// inject default resolvers for $stateProvider for example including appContext
angular.module('inprotech.core').config(function($stateProvider, hotkeysProvider, tmhDynamicLocaleProvider) {
    'use strict';
    var oldState = $stateProvider.state;
    $stateProvider.state = function(name, config) {
        config.resolve = angular.extend({}, {
            appContext: 'appContext'
        }, config.resolve);

        return oldState.apply($stateProvider, arguments);
    };

    tmhDynamicLocaleProvider.localeLocationPattern('condor/i18n/angular-locale_{{locale}}.js');

    hotkeysProvider.includeCheatSheet = false;
});

// changing the default behavior of hotkeys for our purposes
angular.module('inprotech.core').run(function(hotkeyService) {
    'use strict';

    hotkeyService.init();
});

