(function() {
    'use strict';
    
    angular.module('inprotech.dev', [
        'inprotech.components',
        'kendo.directives',
        'inprotech.core',
        'inprotech.api'
    ]);

    angular.module('inprotech.dev').config(function($stateProvider) {
        $stateProvider.state('dev/keyboardshortcut', {
            url: '/dev/keyboardshortcut',
            templateUrl: 'condor/dev/keyboardshortcut.html',
            controller: 'KeyboardShortcutController',
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/datepicker', {
            url: '/dev/datepicker',
            templateUrl: 'condor/dev/datepicker/datepicker.html',
            controller: 'DatePickerController',
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/sqlTextArea', {
            url: '/dev/sqlTextArea',
            templateUrl: 'condor/dev/sqlTextArea/sql-text-area.html',
            controller: 'SQLTextAreaController',
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/grid', {
            url: '/dev/grid',
            templateUrl: 'condor/dev/grid/grid.html',
            controller: 'GridController',
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/gridColumn', {
            url: '/dev/gridColumn',
            templateUrl: 'condor/dev/gridColumn/gridColumn.html',
            controller: 'GridColumnController',
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/topics', {
            url: '/dev/topics',
            templateUrl: 'condor/dev/topics/topics.html',
            controller: 'TestTopicsController',
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/barchart', {
            url: '/dev/barchart',
            templateUrl: 'condor/dev/barchart/barchart.html',
            controller: 'BarchartController',
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/detailpage', {
            url: '/dev/detailpage/{id}',
            templateUrl: 'condor/dev/page/navigation.html',
            controller: 'DevDetailPageNavController',
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/login', {
            url: '/dev/login',
            templateUrl: 'condor/dev/login.html',
            controller: 'DevLoginController',
            controllerAs: 'vm'
        });

        $stateProvider.state('/dev/typeahead', {
            url: '/dev/typeahead',
            templateUrl: 'condor/dev/typeahead/index.html',
            controller: 'DevTypeaheadController',
            controllerAs: 'vm'
        });

        $stateProvider.state('/dev/form', {
            url: '/dev/form',
            templateUrl: 'condor/dev/form/index.html',
            controller: 'DevFormController',
            controllerAs: 'vm'
        });

        $stateProvider.state('/dev/modal', {
            url: '/dev/modal',
            templateUrl: 'condor/dev/modal/modal.html',
            controller: 'DevModalController',
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/exchange', {
            url: '/dev/exchange',
            templateUrl: 'condor/dev/exchange/test.html',
            controller: "DevExchangeController",
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/menu', {
            url: '/dev/menu',
            templateUrl: 'condor/dev/menu/test.html',
            controller: "MenuController",
            controllerAs: 'vm'
        });

        $stateProvider.state('dev/splitter', {
            url: '/dev/splitter',
            templateUrl: 'condor/dev/splitter/test.html',
            controller: "SplitterController",
            controllerAs: 'vm'
        });
    });

    angular.module('inprotech.dev').config(function(typeaheadConfigProvider) {
        typeaheadConfigProvider.config('dev.criteria', {
            label: 'Criteria',
            keyField: 'id',
            textField: 'description',
            apiUrl: 'api/configuration/rules/workflows/typeaheadSearch',
            picklistDisplayName: 'Criteria',
            picklistColumns: '[{title:"Criteria No", field:"id"}, {title:"Description", field:"description"}]'
        });
    });
})();