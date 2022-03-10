(function() {
    'use strict';



    angular.module('inprotech.picklists')
        .controller('actionsController', function($http, $scope, states, modalService) {
            var aCtrl = this;
            initDefaults();

            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem) {
                listItem.key = maintenanceItem.key;
                listItem.code = maintenanceItem.code;
                listItem.value = maintenanceItem.value;
            };

            $scope.vm.confirmAfterSave = function(entry, afterSaveResponse, callback) {
                if ($scope.vm.isValidCombinationPicklist() && ($scope.vm.maintenanceState == states.adding || $scope.vm.maintenanceState == states.duplicating)) {
                    launchActionOrder(callback);
                } else {
                    callback($scope.vm, afterSaveResponse);
                }
            }

            $http.get('api/picklists/actions/importancelevels')
                .then(function(response) {
                    aCtrl.importanceLevels = response.data;
                    if ($scope.vm.maintenanceState === states.adding) {
                        $scope.vm.entry.importanceLevel = aCtrl.importanceLevels[0].level;
                    }
                });

            aCtrl.toggleMaxCycle = function(model) {
                if (model.entry.unlimitedCycles) {
                    aCtrl.canEnterMaxCycles = false;
                    model.entry.cycles = 9999;
                    return;
                }
                aCtrl.canEnterMaxCycles = true;
            };

            function initDefaults() {
                aCtrl.canEnterMaxCycles = true;
                if ($scope.vm.maintenanceState === states.adding) {
                    $scope.vm.entry.cycles = 1;
                }
            }

            aCtrl.init = function(maintenanceState, entry) {
                if (entry) {
                    if (maintenanceState === states.adding) {
                        entry.actionType = "other";
                    }
                }
            };

            function launchActionOrder(afterSave) {
                var items = allItems();
                var dataItem = _.first(items);

                modalService.openModal({
                    launchSrc: 'maintenance',
                    id: 'ActionOrder',
                    dataItem: dataItem,
                    allItems: items,
                    action: $scope.vm.entry.action,
                    controllerAs: 'ctrl'
                }).then(function() {
                    if (afterSave) {
                        afterSave($scope.vm);
                    }
                });
            }

            function allItems() {
                var items = [];
                _.each($scope.vm.entry.jurisdictions, function(jurisdiction) {
                    items.push({
                        jurisdiction: jurisdiction,
                        propertyType: $scope.vm.entry.propertyType,
                        caseType: $scope.vm.entry.caseType
                    });
                });
                return items;
            }
        });
})();