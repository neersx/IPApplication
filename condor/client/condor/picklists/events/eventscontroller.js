(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('eventsController', ['$http', '$scope', 'ExtObjFactory', 'modalService', function($http, $scope, ExtObjFactory, modalService) {
            var c = this;
            var hasDefaultClientImportance = false;
            var extObjFactory = new ExtObjFactory().useDefaults();
            var state = extObjFactory.createContext();

            c.canEnterMaxCycles = true;
            c.isEventNumberVisible = true;
            c.isReady = false;
            c.isReadOnly = $scope.vm.maintenanceState !== 'adding' && $scope.vm.maintenanceState !== 'updating' && $scope.vm.maintenanceState !== 'duplicating';
            c.hasPropagatableChanges = false;

            c.onBeforeSave = function() {
                if (!c.hasPropagatableChanges) {
                    $scope.vm.saveWithoutValidate();
                } else {
                    var updatedFields = _.filter([{
                        id: "description",
                        updated: c.formData.isDirty('description') && $scope.vm.entry.isDescriptionUpdatable === true
                    }, {
                        id: "internalImportance",
                        updated: c.formData.isDirty('internalImportance')
                    }, {
                        id: "maxCycles",
                        updated: c.formData.isDirty('maxCycles')
                    }, {
                        id: "suppressDueDateCalc",
                        updated: c.formData.isDirty('suppressCalculation')
                    }, {
                        id: "allowDateRecalc",
                        updated: c.formData.isDirty('recalcEventDate')
                    }], function(i) {
                        return i.updated;
                    });
                    modalService.open('ConfirmPropagateEventChanges', null, {
                            viewData: {
                                updatedFields: updatedFields
                            }
                        })
                        .then(function(result) {
                            $scope.vm.entry.propagateChanges = result;
                            $scope.vm.entry.updatedFields = updatedFields;
                            $scope.vm.saveWithoutValidate();
                        });
                }
            };

            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem) {
                listItem.code = maintenanceItem.code;
                listItem.value = maintenanceItem.description;
                //listItem.alias = maintenanceItem.;
                listItem.maxCycles = maintenanceItem.maxCycles;
                listItem.importance = _.find(c.supportData.importanceLevels, {
                    id: maintenanceItem.internalImportance
                }).name;
            };

            $scope.vm.onAfterSave = function() {
                c.formData.save();
            };

            var clearWatch = $scope.$watch('vm.entry', function(entry) {
                if (entry) {
                    c.formData = state.attach($scope.vm.entry, 'key');
                    if ($scope.vm.maintenanceState === 'duplicating') {
                        c.formData.description += ' - Copy';
                        setFormDirty();
                    }
                    $scope.$watch(
                        function() {
                            return (c.formData.isDirty('description') && $scope.vm.entry.isDescriptionUpdatable === true) || c.formData.isDirty('internalImportance') || c.formData.isDirty('maxCycles') || c.formData.isDirty('suppressCalculation') || c.formData.isDirty('recalcEventDate');
                        },
                        function(newValue, oldValue) {
                            if (newValue != oldValue)
                                c.hasPropagatableChanges = newValue;
                        });
                    c.isReady = true;
                    if ($scope.vm.maintenanceState === 'updating') {
                        if ($scope.vm.entry.hasUpdatableCriteria === true) {
                            $scope.vm.onBeforeSave = c.onBeforeSave;
                        } else {
                            $scope.vm.onBeforeSave = null;
                        }
                    }
                    clearWatch();
                }
            });

            $http.get('api/picklists/events/supportdata')
                .then(function(response) {
                    c.supportData = response.data;
                    initDefaults();
                });

            function initDefaults() {
                c.isEventNumberVisible = $scope.vm.maintenanceState !== 'adding' && $scope.vm.maintenanceState !== 'duplicating';
                if ($scope.vm.maintenanceState === 'adding') {
                    c.isEventNumberVisible = false;
                    $scope.vm.entry.internalImportance = c.supportData.defaultImportanceLevel;
                    $scope.vm.entry.clientImportance = c.supportData.defaultImportanceLevel;
                    $scope.vm.entry.maxCycles = c.supportData.defaultMaxCycles;
                    $scope.vm.entry.description = '';
                    $scope.vm.entry.code = '';
                    $scope.vm.entry.unlimitedCycles = false;
                    $scope.vm.entry.notes = '';
                    $scope.vm.entry.category = null;
                    $scope.vm.entry.group = '';
                    $scope.vm.entry.controllingAction = null;
                    $scope.vm.entry.draftCaseEvent = null;
                    $scope.vm.entry.isAccountingEvent = false;
                    $scope.vm.entry.recalcEventDate = false;
                    $scope.vm.entry.allowPoliceImmediate = false;
                    $scope.vm.entry.suppressCalculation = false;
                    $scope.vm.entry.notesGroup = '';
                    $scope.vm.entry.notesSharedAcrossCycles = false;
                    $scope.vm.entry.propagateChanges = false;
                    $scope.vm.entry.hasUpdatableCriteria = false;
                    c.isReady = true;
                    c.formData = state.attach($scope.vm.entry, 'key');
                    if ($scope.vm.searchValue) {
                        c.formData.description = $scope.vm.searchValue;
                        setFormDirty();
                    }
                }
            }

            function setFormDirty() {
                $scope.vm.maintenance.$setDirty();
            }

            c.setClientImportance = function() {
                if (!hasDefaultClientImportance && c.formData.clientImportance) {
                    hasDefaultClientImportance = true;
                }
                if (hasDefaultClientImportance && c.formData.clientImportance) return;
                c.formData.clientImportance = c.formData.internalImportance;
            };

            c.toggleMaxCycle = function(evt) {
                if (evt.target.checked) {
                    c.canEnterMaxCycles = false;
                    c.formData.maxCycles = 9999;
                    return;
                }
                c.canEnterMaxCycles = true;
            };
        }]);
})();