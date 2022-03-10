(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('subTypesController', ['$scope', function($scope) {
            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem) {
                if (maintenanceItem.subtype) {
                    listItem.key = maintenanceItem.subtype.key;
                    listItem.code = maintenanceItem.subtype.code;
                    listItem.value = maintenanceItem.validDescription;
                    listItem.isDefaultJurisdiction = maintenanceItem.jurisdictions[0].code === 'ZZZ';
                } else {
                    listItem.code = maintenanceItem.code;
                    listItem.value = maintenanceItem.value;
                }
            };
        }])
        .factory('subTypesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/subtypes'), {});
            }
        ]);
})();
