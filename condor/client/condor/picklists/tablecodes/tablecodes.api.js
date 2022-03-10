(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('tableCodesController', ['$scope', function($scope) {
            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem){
                listItem.code = maintenanceItem.code;
                listItem.value = maintenanceItem.value;
            };
        }])
        .factory('tablecodesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/tablecodes'), {});
            }
        ]);
})();
