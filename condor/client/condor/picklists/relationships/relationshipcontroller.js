(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('relationshipController', ['$scope', function($scope) {
            var rCtrl = this;
            rCtrl.onEventChange = onEventChange;
            rCtrl.init = init;

            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem){
                listItem.code = maintenanceItem.code;
                listItem.value = maintenanceItem.value;
                listItem.fromEvent = maintenanceItem.fromEvent;
                listItem.toEvent = maintenanceItem.toEvent;
                listItem.displayEvent = maintenanceItem.displayEvent;
                listItem.notes = maintenanceItem.notes;
                listItem.earliestDateFlag = maintenanceItem.earliestDateFlag;
                listItem.pointsToParent = maintenanceItem.pointsToParent;
                listItem.showFlag = maintenanceItem.showFlag;
                listItem.priorArtFlag = maintenanceItem.priorArtFlag;
            };

            function onEventChange(entry, src, maintenance) {
                if (src === 'fromEvent') {
                    if (!entry.toEvent) {
                        entry.toEvent = entry.fromEvent;
                    }
                } else {
                    if (!entry.fromEvent) {
                        entry.fromEvent = entry.toEvent;
                    }
                }
                resetError(maintenance);
            }

            function init(model) {
                if(model.maintenanceState === 'adding') {
                    model.entry.showFlag = 1;
                }
            } 

            function resetError(maintenance) {
                if (maintenance.fromEvent.$fieldError) {
                    maintenance.fromEvent.$setValidity('fieldError', null);
                    maintenance.fromEvent.$fieldError = null;
                }
                if (maintenance.toEvent.$fieldError) {
                    maintenance.toEvent.$setValidity('fieldError', null);
                    maintenance.toEvent.$fieldError = null;
                }
            }
        }]);
})();
