(function() {
    'use strict';

    angular.module('inprotech.configuration.system.mui', [
        'inprotech.configuration',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.system.mui').config(function($stateProvider) {
        $stateProvider
            .state('screenTranslations', {
                url: '/configuration/system/mui/screen-translations-utility',
                templateUrl: 'condor/configuration/system/mui/screen-translations-utility.html',
                controller: 'ScreenTranslationsController',
                controllerAs: 'vm',
                resolve: {
                    viewData: function($http) {
                        return $http.get('api/configuration/system/mui/view').then(function(response) {
                            return response.data;
                        });
                    }
                },
                data: {
                    pageTitle: 'Screen Translations Utility'
                }
            })
    });
})();
