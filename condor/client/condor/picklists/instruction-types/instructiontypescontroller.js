(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('instructionTypesController', ['$http', '$scope', function($http, $scope) {
			var itCtrl = this;

            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem){
                var recordedAgainst = maintenanceItem.recordedAgainstId ?
                                      _.find(itCtrl.nameTypes, function(x) {return x.key == maintenanceItem.recordedAgainstId}).value :
                                      null;

                var restrictedBy = maintenanceItem.restrictedById?
                                   _.find(itCtrl.nameTypes, function(x) {return x.key == maintenanceItem.restrictedById}).value :
                                   null;

                listItem.code = maintenanceItem.code;
                listItem.value = maintenanceItem.value;
                listItem.recordedAgainst = recordedAgainst;
                listItem.recordedAgainstId = maintenanceItem.recordedAgainstId;
                listItem.restrictedBy = restrictedBy;
                listItem.restrictedById = maintenanceItem.restrictedById;
            };
            
            $http.get('api/picklists/instructionTypes/nameTypes')
                .then(function(response) {
                    itCtrl.nameTypes = response.data;
                });
        }]);
})();
