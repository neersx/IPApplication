(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('caseTypesController', ['$scope', function($scope) {
            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem) {
                listItem.key = maintenanceItem.key;
                listItem.code = maintenanceItem.code;
                listItem.value = maintenanceItem.value;
                listItem.actualCaseType = maintenanceItem.actualCaseType;
            };
        }])
        .factory('caseTypesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/casetypes'), {});
            }
        ]);
})();