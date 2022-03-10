(function() {
    'use strict';

    angular.module('inprotech.configuration.general.standinginstructions', [
        'inprotech.configuration',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.standinginstructions').config(function($stateProvider) {
        $stateProvider.state('standinginstructions', {
            url: '/configuration/general/standinginstructions',
            templateUrl: 'condor/configuration/general/standinginstructions/standinginstructions.html',
            controller: 'StandingInstructionsController',
            controllerAs: 'si',
            data: {
                pageTitle: 'Standing Instructions Maintenance'
            }
        });
    });
})();

