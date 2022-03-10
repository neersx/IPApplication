angular.module('inprotech.configuration.general.jurisdictions')
    .controller('StatusFlagsController', function ($scope, kendoGridBuilder, jurisdictionStatusFlagsService, jurisdictionMaintenanceService, inlineEdit, hotkeys) {
        'use strict';

        var vm = this;
        var parentId;
        vm.$onInit = onInit;        

        function onInit() {
            parentId = $scope.parentId;
            vm.gridOptions = buildGridOptions();
            vm.onAddClick = onAddClick;
            vm.registrationStatus = jurisdictionStatusFlagsService.registrationStatus;
            vm.initialize = initialize;
            vm.statusFlagChange = statusFlagChange;
            vm.checkDuplicateError = checkDuplicateError;
            vm.initialize();

            _.extend(vm.topic, {
                getFormData: getFormData,
                hasError: hasError,
                isDirty: isDirty,
                validate: validate,
                initializeShortcuts: initShortcuts
            });
            vm.topic.initialised = true;
        }

        function initialize() {
            jurisdictionStatusFlagsService.copyProfiles().then(function (response) {
                vm.copyProfiles = response.data;
            });
        }

        var createObj = inlineEdit.defineModel([
            'id',
            'countryId',
            'name',
            'restrictRemoval',
            'allowNationalPhase',
            'profileName',
            'status',
            'registrationStatus'
        ]);

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'statusFlagsGrid',
                autoBind: true,
                pageable: false,
                sortable: false,
                autoGenerateRowTemplate: vm.topic.canUpdate,
                read: function (queryParams) {
                    return jurisdictionStatusFlagsService.search(queryParams, parentId).then(function (data) {
                        return _.map(data, createObj);
                    });
                },
                rowAttributes: 'ng-form="rowForm" ng-class="{error: rowForm.$invalid || dataItem.hasError(), edited: dataItem.added || dataItem.isDirty(), deleted: dataItem.deleted}"' +
                    'uib-tooltip="{{\'jurisdictions.maintenance.designationStages.duplicate\' | translate}}" tooltip-enable="dataItem.error(\'duplicate\')" tooltip-class="tooltip-error" data-tooltip-placement="left"',
                actions: vm.topic.canUpdate ? {
                    delete: {
                        onClick: 'vm.checkDuplicateError(dataItem)'
                    }
                } : null,
                columns: [{
                    title: 'jurisdictions.maintenance.designationStages.designationStage',
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.name"></span>' +
                        '<ip-text-field ng-if="!dataItem.deleted" label="" ip-required name="name" ng-maxlength="30" ng-model="dataItem.name" ng-change="vm.statusFlagChange(dataItem)"></ip-text-field>' : '<span ng-bind="dataItem.nameTranslated"></span>'
                }, {
                    title: 'jurisdictions.maintenance.designationStages.restrictRemoval',
                    template: '<input ng-model="dataItem.restrictRemoval" type="checkbox" ng-disabled="!vm.topic.canUpdate || dataItem.deleted" />'
                }, {
                    title: 'jurisdictions.maintenance.designationStages.allowNationalPhase',
                    template: '<input ng-model="dataItem.allowNationalPhase" type="checkbox" ng-disabled="!vm.topic.canUpdate || dataItem.deleted" />'
                }, {
                    title: 'jurisdictions.maintenance.designationStages.registrationStatus',
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.registrationStatus"></span>' +
                        '<ip-dropdown ng-if="!dataItem.deleted" label="" ip-required name="registrationStatus" ng-model="dataItem.status"  options="option.key as option.value for option in vm.registrationStatus"></ip-dropdown>' : '<span ng-bind="dataItem.registrationStatus"></span>'
                },
                {
                    title: 'jurisdictions.maintenance.designationStages.caseCreationCopyProfile',
                    field: 'profileName',
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.profileName"></span>' +
                        '<ip-dropdown ng-if="!dataItem.deleted" label="" name="profileName" ng-model="dataItem.profileName"  options="option.key as option.value for option in vm.copyProfiles"></ip-dropdown>' : '<span ng-bind="dataItem.profileName"></span>'
                }
                ]
            });
        }

        function statusFlagChange(dataItem) {
            vm.checkDuplicateError(dataItem);
        }

        function checkDuplicateError(dataItem) {
            var itemsToBeValidated = _.filter(vm.gridOptions.dataSource.data(), function (item) {
                return !item.deleted;
            });
            if (isDuplicate(itemsToBeValidated, dataItem) && !dataItem.deleted) {
                dataItem.error('duplicate', true);
            } else {
                dataItem.error('duplicate', false);
            }
            var allItems = _.without(itemsToBeValidated, dataItem);
            _.each(allItems, function (r) {
                if (r.hasError()) {
                    if (!isDuplicate(allItems, r)) {
                        r.error('duplicate', false);
                    }
                }
            });
        }

        function isDuplicate(allItems, dataItem) {
            return jurisdictionMaintenanceService.isDuplicated(allItems, dataItem, ['name']);
        }

        function onAddClick() {
            var insertIndex = vm.gridOptions.dataSource.total();
            var newStatusFlag = createObj();
            newStatusFlag.countryCode = vm.parentId;
            newStatusFlag.id = -1;
            vm.gridOptions.insertRow(insertIndex, newStatusFlag);
        }

        function hasError() {
            return vm.form.$invalid || inlineEdit.hasError(vm.gridOptions.dataSource.data());
        }

        function isDirty() {
            return inlineEdit.canSave(vm.gridOptions.dataSource.data());
        }

        function validate() {
            return vm.form.$validate();
        }

        function getFormData() {
            var delta = inlineEdit.createDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);
            return {
                statusFlagsDelta: delta
            };
        }

        function convertToSaveModel(dataItem) {
            var updatedRecord = {
                id: dataItem.id,
                countryId: parentId,
                name: dataItem.name,
                restrictRemoval: dataItem.restrictRemoval,
                allowNationalPhase: dataItem.allowNationalPhase,
                profileName: dataItem.profileName,
                status: dataItem.status
            };
            return updatedRecord;
        }

        function initShortcuts() {
            if (vm.topic.canUpdate) {
                hotkeys.add({
                    combo: 'alt+shift+i',
                    description: 'shortcuts.add',
                    callback: onAddClick
                });
            }
        }
        
    });