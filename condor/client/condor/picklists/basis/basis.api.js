(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('basisController', ['$scope', function($scope) {
            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem) {
                if (maintenanceItem.basis) {
                    listItem.key = maintenanceItem.basis.key;
                    listItem.code = maintenanceItem.basis.code;
                    listItem.value = maintenanceItem.validDescription;
                    listItem.isDefaultJurisdiction = maintenanceItem.jurisdictions[0].code === 'ZZZ';
                } else {
                    listItem.code = maintenanceItem.code;
                    listItem.value = maintenanceItem.value;
                }
            };
        }])
        .factory('basisApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/basis'), {});
            }
        ]);
})();