angular.module('inprotech.configuration.general.validcombination')
    .controller('ValidCombinationMaintenanceController', ValidCombinationMaintenanceController);



function ValidCombinationMaintenanceController($scope, $uibModalInstance, notificationService, validCombinationService, states, validCombinationMaintenanceService, validCombinationConfig, modalService, modalOptions, hotkeys, validCombinationConfirmationService) {
    'use strict';

    var vm = this;

    vm.onCharacteristicsChanged = onCharacteristicsChanged;
    vm.cancel = cancel;
    vm.save = save;
    vm.afterSave = afterSave;
    vm.afterSaveError = afterSaveError;
    vm.entity = modalOptions.entity;
    vm.viewData = modalOptions.viewData;
    vm.selectedCharacteristic = modalOptions.selectedCharacteristic;
    vm.entityState = modalOptions.state;
    vm.entity.state = modalOptions.state;
    vm.searchCriteria = modalOptions.searchCriteria;
    vm.launchActionOrder = angular.noop;
    vm.isCopy = false;
    vm.copyEntity = {};
    vm.isCopyChanged = isCopyChanged;
    vm.enableCopySave = angular.noop;
    vm.initShortcuts = initShortcuts;
    vm.disable = disable;
    vm._isSaving = false;

    vm.characteristics = _.filter(vm.viewData, function (characteristic) {
        return characteristic.type !== validCombinationConfig.searchType.allCharacteristics;
    });

    onCharacteristicsChanged();

    function onCharacteristicsChanged(maintenance) {
        var baseUrl = 'condor/configuration/general/validcombination/';
        var type = vm.selectedCharacteristic.type;
        if (type === validCombinationConfig.searchType.default || type === validCombinationConfig.searchType.allCharacteristics) {
            vm.templateUrl = '';
            vm.controllerName = '';
        } else {
            vm.templateUrl = baseUrl + type + '/' + type + '.maintenance.html';
            vm.controllerName = type + 'MaintenanceController';
            if (maintenance) {
                maintenance.$dirty = false;
                maintenance.$setPristine();
            }
        }
        resetEntity();
    }

    function initShortcuts(maintenance) {
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function () {
                if (!vm.disable() && modalService.canOpen('ValidCombinationMaintenance')) {
                    vm.save(maintenance);
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.revert',
            callback: function () {
                if (modalService.canOpen('ValidCombinationMaintenance')) {
                    vm.dismissAll(maintenance);
                }
            }
        });
    }

    function resetEntity() {
        if (vm.entityState !== 'adding') {
            return;
        }

        vm.entity = {
            state: vm.entityState
        };
    }

    function isCopyChanged(maintenance) {
        resetEntity();
        vm.copyEntity = {};
        if (maintenance) {
            maintenance.$dirty = false;
            maintenance.$setPristine();
        }
    }

    function cancel() {
        changeAlertSize('lg');
        $uibModalInstance.dismiss('Cancel');
    }

    function disable() {
        return vm.isCopy ? !vm.enableCopySave() : !(vm.maintenance && (vm.maintenance.$dirty || (vm.entity && vm.entity.prepopulated)) && vm.maintenance.$valid);
    }

    function dismiss(client) {
        if (vm.isCopy) {
            return !client.$dirty && typeof vm.copyEntity.picklistsDirty !== 'undefined' && !vm.copyEntity.picklistsDirty();
        }
        return vm.selectedCharacteristic.type === validCombinationConfig.searchType.default || !client.$dirty;
    }

    vm.dismissAll = function (client) {
        if (dismiss(client)) {
            cancel();
            return;
        }

        notificationService.discard()
            .then(function () {
                cancel();
            });
    };

    function save(client) {
        if (vm._isSaving) return;
        if (client && client.$validate) {
            client.$validate();
        }
        if (client.$invalid) {
            return;
        }
        if (vm.isCopy) {
            if (vm.copyEntity.hasSameValue()) {
                changeAlertSize('md');
                notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: 'validcombinations.alertSameJurisdiction'
                });
            } else {
                var allCharacteristics = [{
                    description: 'validcombinations.propertyType',
                    isSelected: vm.copyEntity.propertyType
                }, {
                    description: 'validcombinations.category',
                    isSelected: vm.copyEntity.category
                }, {
                    description: 'validcombinations.subType',
                    isSelected: vm.copyEntity.subType
                }, {
                    description: 'validcombinations.basis',
                    isSelected: vm.copyEntity.basis
                }, {
                    description: 'validcombinations.action',
                    isSelected: vm.copyEntity.action
                }, {
                    description: 'validcombinations.status',
                    isSelected: vm.copyEntity.status
                }, {
                    description: 'validcombinations.checklist',
                    isSelected: vm.copyEntity.checklist
                }, {
                    description: 'validcombinations.relationship',
                    isSelected: vm.copyEntity.relationship
                }];

                var selectedCharacterisics = _.filter(allCharacteristics, function (characteristic) {
                    return characteristic.isSelected === true;
                });

                var options = {
                    confirmationMessage: 'validcombinations.confirmSaveCopyValidCombination',
                    templateUrl: 'condor/configuration/general/validcombination/copyvalidcombination-confirmation.html',
                    continue: 'modal.confirmation.save',
                    cancel: 'modal.confirmation.cancel',
                    selectedCharacterisics: selectedCharacterisics,
                    fromJurisdiction: vm.copyEntity.fromJurisdiction.value
                };
                notificationService.confirm(options).then(function () {
                    vm._isSaving = true;
                    validCombinationService.copy(vm.copyEntity).then(afterSave, afterSaveError);
                });
            }
        } else {
            vm._isSaving = true;
            if (vm.entityState === states.adding || vm.entityState === states.duplicating) {
                validCombinationService.add(vm.entity, vm.selectedCharacteristic)
                    .then(afterSave, afterSaveError);
            } else {
                validCombinationService.update(vm.entity, vm.selectedCharacteristic)
                    .then(afterSave, afterSaveError);
            }
        }
    }

    function afterSave(response) {
        if (response.data.result.result === 'success') {
            changeAlertSize('lg');
            $uibModalInstance.close();
            if (response.data.result.updatedKeys !== null) {
                validCombinationMaintenanceService.addSavedKeys(response.data.result.updatedKeys);
            }
            if (!vm.isCopy && vm.selectedCharacteristic.type === validCombinationConfig.searchType.action && (vm.entity.state === states.adding || vm.entity.state === states.duplicating)) {
                vm.launchActionOrder();
            }
        } else if (response.data.result.result === 'confirmation') {
            vm._isSaving = false;
            validCombinationConfirmationService.confirm(vm.entity, response.data.result, onConfirmAfterSave);
        } else {
            vm._isSaving = false;
            changeAlertSize('md');
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: response.data.result.message
            });
        }
    }

    function onConfirmAfterSave(entity) {
        validCombinationService.add(entity, vm.selectedCharacteristic)
            .then(afterSave, afterSaveError);
    }

    function changeAlertSize(size) {
        var registry = modalService.getRegistry();
        if (angular.isDefined(registry.Alert) && registry.Alert !== null) {
            registry.Alert.options.size = size;
        }
    }

    function afterSaveError(response) {
        vm._isSaving = false;
        changeAlertSize('md');
        notificationService.alert({
            message: 'modal.alert.unsavedchanges',
            errors: _.where(response.data.errors, {
                field: null
            })
        });
    }
}