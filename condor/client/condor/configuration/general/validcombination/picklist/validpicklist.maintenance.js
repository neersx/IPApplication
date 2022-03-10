angular.module('inprotech.configuration.general.validcombination')
    .directive('ipValidPicklistMaintenance', function() {
        'use strict';

        return {
            restrict: 'E',
            templateUrl: function(elem, attrs) {
                return 'condor/configuration/general/validcombination/' + attrs.entityType.toLowerCase() + '/valid' + attrs.entityType.toLowerCase() + '.maintenance.html'
            },
            scope: {
                model: '=',
                maintenance: '=',
                state: '=',
                canMaintain: '@?',
                entityType: '@',
                searchCriteria: '=?',
                src: '@?'
            },
            bindToController: {
                onBeforeSave: '=?',
                saveWithoutValidate: '=?',
                hasInlineGridError: '=?',
                isInlineGridDirty: '=?'
            },
            controller: 'validPicklistMaintenanceController',
            controllerAs: 'vm'
        };
    });