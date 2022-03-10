angular.module('inprotech.configuration.general.importancelevel')
    .controller('ImportanceLevelController', ImportanceLevelController);

function ImportanceLevelController($scope, kendoGridBuilder, importanceLevelService, workflowsEntryControlService, notificationService, $translate, hotkeys, kendoGridService) {
    'use strict';

    var vm = this;
    var workflowService;
    vm.$onInit = onInit;

    function onInit() {
        workflowService = workflowsEntryControlService;
        vm.gridOptions = buildGridOptions();
        vm.initShortcuts = initShortcuts;
        vm.onAddClick = onAddClick;
        vm.checkLevelDuplicate = checkLevelDuplicate;
        vm.checkDescriptionDuplicate = checkDescriptionDuplicate;
        vm.isSaveEnabled = isSaveEnabled;
        vm.isDiscardEnabled = isDiscardEnabled;
        vm.discard = discard;
        vm.save = save;
        vm.onLevelChanged = onLevelChanged;
        vm.onDescriptionChanged = onDescriptionChanged;
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'importanceGrid',
            autoBind: true,
            actions: {
                delete: true
            },
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-form="rowForm" ng-class="{error: rowForm.$invalid || dataItem.inUse || dataItem.error, edited: dataItem.isEdited || dataItem.added ||dataItem.deleted, deleted: dataItem.deleted}"',
            serverFiltering: false,
            read: function () {
                return importanceLevelService.search();
            },
            columns: [{
                title: 'importanceLevel.importance',
                width: '10%',
                fixed: true,
                template: '<span ng-if="dataItem.deleted" ng-bind="dataItem.level"></span>' +
                    '{{vm.checkLevelDuplicate(dataItem, rowForm)}}' +
                    '<ip-text-field ng-if="dataItem.added" focus-on-add ip-required label="" name="level" ng-model="dataItem.level" ng-change="vm.onLevelChanged(dataItem, rowForm)" ng-maxlength="2"></ip-text-field>' + '<span ng-if="!dataItem.added && !dataItem.deleted" ng-bind="dataItem.level"></span>'
            }, {
                title: 'importanceLevel.description',
                width: '90%',
                fixed: true,
                template: '<span ng-if="dataItem.deleted" ng-bind="dataItem.description"></span>' +
                    '{{vm.checkDescriptionDuplicate(dataItem, rowForm)}}' +
                    '<ip-text-field id="{{dataItem.level}}" ng-if="!dataItem.deleted" ip-required label="" name="description" ng-model="dataItem.description" ng-maxlength="30" ng-change="vm.onDescriptionChanged(dataItem, rowForm)"></ip-text-field>'
            }]
        });
    }

    function onAddClick() {
        var insertIndex = vm.gridOptions.dataSource.total();
        vm.gridOptions.insertRow(insertIndex, {
            added: true
        });
    }

    function isAdded(data) {
        return (data.added || data.isAdded) && !data.deleted;
    }

    function isDeleted(data) {
        return data.deleted;
    }

    function isUpdated(data) {
        return (data.isEdited) && !data.deleted && !(data.added || data.isAdded);
    }

    function onLevelChanged(dataItem, rowForm) {
        dataItem.isEdited = true;
        dataItem.error = false;
        rowForm.level.$setValidity('duplicate', true);
        if (!dataItem.duplicatedFields) {
            dataItem.duplicatedFields = [];
        } else if (_.contains(dataItem.duplicatedFields, 'level')) {
            dataItem.duplicatedFields = _.without(dataItem.duplicatedFields, 'level');
        }
        if (isDuplicate(dataItem, 'level')) {
            rowForm.level.$setValidity('duplicate', false);
            dataItem.duplicatedFields.push('level');
        }
    }

    function onDescriptionChanged(dataItem, rowForm) {
        dataItem.isEdited = true;
        dataItem.inUse = false;
        dataItem.error = false;
        rowForm.description.$setValidity('duplicate', true);
        if (!dataItem.duplicatedFields) {
            dataItem.duplicatedFields = [];
        } else if (_.contains(dataItem.duplicatedFields, 'description')) {
            dataItem.duplicatedFields = _.without(dataItem.duplicatedFields, 'description');
        }
        if (isDuplicate(dataItem, 'description')) {
            rowForm.description.$setValidity('duplicate', false);
            dataItem.duplicatedFields.push('description');
        }
    }

    function isSaveEnabled() {
        return kendoGridService.isGridDirty(vm.gridOptions) && !vm.form.$invalid && !hasDuplicate();
    }

    function isDiscardEnabled() {
        return kendoGridService.isGridDirty(vm.gridOptions);
    }

    function mapGridDelta(data, mapFunc) {
        return {
            added: _.chain(data).filter(isAdded).map(mapFunc).value(),
            deleted: _.chain(data).filter(isDeleted).map(mapFunc).value(),
            updated: _.chain(data).filter(isUpdated).map(mapFunc).value()
        };
    }

    function getFormData() {
        var delta = mapGridDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);
        return delta;
    }

    function convertToSaveModel(data) {
        return {
            level: data.level,
            description: data.description
        };
    }

    function save() {
        if (validate() && !hasDuplicate()) {
            var formDelta = getFormData();
            importanceLevelService.save(formDelta).then(function (response) {
                if (response.data.result === 'success') {
                    notificationService.success();
                    vm.gridOptions.search();
                } else if (response.data.result === 'error') {
                    var deleteValidationErrors = _.filter(response.data.validationErrors, function (ve) {
                        return ve.inUseIds && ve.inUseIds.length > 0;
                    });
                    if (deleteValidationErrors && deleteValidationErrors.length > 0) {
                        var allInUse = formDelta.deleted.length === deleteValidationErrors.length;
                        var message = allInUse ? $translate.instant('modal.alert.alreadyInUse') :
                            $translate.instant('modal.alert.partialComplete') + '<br/>' + $translate.instant('modal.alert.alreadyInUse');
                        var title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';

                        vm.gridOptions.search().then(function () {
                            notificationService.alert({
                                title: title,
                                message: message
                            });
                            markInUseItems(_.first(deleteValidationErrors).inUseIds);
                        });
                    }

                    var otherValidationErrors = _.filter(response.data.validationErrors, function (ve) {
                        return ve.field !== null && ve.Id !== null;
                    });
                    if (otherValidationErrors.length > 0) {
                        setError(response.data.validationErrors);
                    }
                }
            });
        }
    }

    function setError(errors) {
        _.chain(errors)
            .each(applyError);
    }

    function applyError(error) {
        var item = _.first(_.filter(vm.gridOptions.dataSource.data(), function (i) {
            return (isAdded(i) || isUpdated(i)) && i.level === error.id;
        }));

        if (item) {
            item.error = true;
        }
    }

    function markInUseItems(inUseIds) {
        _.each(vm.gridOptions.data(), function (item) {
            _.each(inUseIds, function (inUseId) {
                if (item.level === inUseId) {
                    item.inUse = true;
                }
            });
        });
    }

    function validate() {
        return vm.form.$validate();
    }

    function discard() {
        return vm.gridOptions.search();
    }

    function checkLevelDuplicate(dataItem, rowForm) {
        if (dataItem.duplicatedFields && _.contains(dataItem.duplicatedFields, 'level') && rowForm.level) {
            rowForm.level.$setValidity('duplicate', false);
        }
    }

    function checkDescriptionDuplicate(dataItem, rowForm) {
        if (dataItem.duplicatedFields && _.contains(dataItem.duplicatedFields, 'description') && rowForm.description) {
            rowForm.description.$setValidity('duplicate', false);
        }
    }

    function isDuplicate(dataItem, prop) {
        var all = vm.gridOptions.dataSource.data();
        return workflowService.isDuplicated(_.without(all, dataItem), dataItem, [prop]);
    }

    function hasDuplicate() {
        var all = vm.gridOptions.dataSource.data();
        all = _.filter(all, function (item) {
            return item.deleted ? false : true;
        });

        var duplicateExists = _.any(all, function (record) {
            return record.duplicatedFields && _.any(record.duplicatedFields);
        });

        return duplicateExists;
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+i',
            description: 'shortcuts.add',
            callback: function () {
                vm.onAddClick();
            }
        });
    }
}