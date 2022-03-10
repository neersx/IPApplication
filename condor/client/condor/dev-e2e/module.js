(function() {
    'use strict';

    angular.module('inprotech.deve2e', [
        'inprotech.components'
    ]);

    angular.module('inprotech.deve2e').config(function($stateProvider) {
        $stateProvider.state('deve2e', {
            url: '/deve2e/detailpage',
            templateUrl: 'condor/dev-e2e/detail-page/detailPage.test.html',
            controller: 'DetailPageTestController',
            controllerAs: 'vm'
        });

        $stateProvider.state('deve2e/datepicker', {
            url: '/deve2e/datepicker',
            templateUrl: 'condor/dev-e2e/datepicker/datepicker.html',
            controller: 'DatepickerTestController',
            controllerAs: 'vm'
        });

        $stateProvider.state('deve2e/picklist', {
            url: '/deve2e/picklist',
            templateUrl: 'condor/dev-e2e/picklist/picklist.test.html',
            controller: 'PicklistTestController',
            controllerAs: 'vm'
        });
        
        $stateProvider.state('deve2e/grid', {
            url: '/deve2e/grid',
            templateUrl: 'condor/dev-e2e/grid/grid.test.html',
            controller: 'GridTestController',
            controllerAs: 'vm'
        });

        $stateProvider.state('deve2e/quick-search', {
            url: '/deve2e/quick-search',
            templateUrl: 'condor/dev-e2e/quick-search/quick-search.test.html',
            controller: 'QuickSearchTestController',
            controllerAs: 'vm'
        });

        $stateProvider.state('deve2e/sql-text-area', {
            url: '/deve2e/sqlTextArea',
            templateUrl: 'condor/dev-e2e/sqlTextArea/sql-text-area.test.html',
            controller: 'SQLTextAreaTestController',
            controllerAs: 'vm'
        });
    });
})();