(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('checklistController', function($scope, states) {
            var iCtrl = this;

            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem){
                listItem.code = maintenanceItem.key;
                listItem.value = maintenanceItem.value;
                listItem.checklistType = maintenanceItem.checklistType;
            };

            iCtrl.init = function(maintenanceState, entry) {
                if (maintenanceState === states.adding) {
                    entry.checklistType = "other";
                }
            };
        });
})();