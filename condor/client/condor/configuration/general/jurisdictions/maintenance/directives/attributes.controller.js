angular.module('inprotech.configuration.general.jurisdictions')
    .controller('AttributesController', function ($scope, kendoGridBuilder, jurisdictionAttributesService, jurisdictionMaintenanceService, inlineEdit, hotkeys) {
        'use strict';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            vm.formData = {}
            vm.formData.reportPriorArt = $scope.vm.topic.reportPriorArt;
            vm.parentId = $scope.parentId;
            vm.initialize = initialize;
            vm.initialize();
            vm.gridOptions = buildGridOptions();
            vm.attributesTypeChange = attributesTypeChange;
            vm.attributesChange = attributesChange;
            vm.onAddClick = onAddClick;
            vm.checkDuplicateError = checkDuplicateError;

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
            jurisdictionAttributesService.getAttributeTypes().then(function (data) {
                vm.attributeTypes = data.data;
            });

        }

        var createObj = inlineEdit.defineModel([
            'id',
            'typeId',
            'valueId',
            'countryCode',
            'typeName',
            'value'
        ]);

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'attributesList',
                topicItemNumberKey: vm.topic.key,
                autoBind: true,
                pageable: false,
                sortable: false,
                read: function (queryParams) {
                    return jurisdictionAttributesService.listAttributes(queryParams, vm.parentId).then(function (data) {
                        return _.map(data, createObj);
                    });
                },
                autoGenerateRowTemplate: vm.topic.canUpdate,
                actions: vm.topic.canUpdate ? {
                    delete: {
                        onClick: 'vm.checkDuplicateError(dataItem)'
                    }
                } : null,
                rowAttributes: 'ng-form="rowForm" ng-class="{error: rowForm.$invalid || dataItem.hasError(), edited: dataItem.added || dataItem.isDirty(), deleted: dataItem.deleted}"' +
                    'uib-tooltip="{{\'jurisdictions.maintenance.attributes.duplicate\' | translate}}" tooltip-enable="dataItem.error(\'duplicate\')" tooltip-class="tooltip-error" data-tooltip-placement="left"',
                columns: [{
                    width: '30%',
                    title: 'jurisdictions.maintenance.attributes.type',
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.typeName"></span>' +
                        '<ip-dropdown ng-if="!dataItem.deleted" label="" focus-on-add ip-required name="jurisdictionAttributeType" ng-model="dataItem.typeId"  options="option.key as option.value for option in vm.attributeTypes" ng-change="vm.attributesTypeChange(dataItem)"></ip-dropdown>' : '<span ng-bind="dataItem.typeName"></span>'
                }, {
                    title: 'jurisdictions.maintenance.attributes.value',
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.value"></span>' +
                        '<ip-dropdown ng-if="!dataItem.deleted" label="" ip-required name="jurisdictionAttribute" ng-model="dataItem.valueId"  options="option.key as option.value for option in dataItem.attributes" ng-change="vm.attributesChange(dataItem)"></ip-dropdown>' : '<span ng-bind="dataItem.value"></span>'
                }]
            });
        }

        function attributesTypeChange(dataItem) {
            if (!dataItem.typeId) {
                dataItem.attributes = {};
                dataItem.valueId = null;
                return;
            }
            jurisdictionAttributesService.getAttributes(dataItem.typeId).then(function (data) {
                dataItem.attributes = data.data;
            });
        }

        function attributesChange(dataItem) {
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
            return jurisdictionMaintenanceService.isDuplicated(allItems, dataItem, ['typeId', 'valueId']);
        }

        function onAddClick() {
            var insertIndex = vm.gridOptions.dataSource.total();
            var newAttribute = createObj();
            newAttribute.countryCode = vm.parentId;
            newAttribute.id = -1;
            vm.gridOptions.insertRow(insertIndex, newAttribute);
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

        function hasError() {
            return vm.form.$invalid || inlineEdit.hasError(vm.gridOptions.dataSource.data());
        }

        function isDirty() {
            return inlineEdit.canSave(vm.gridOptions.dataSource.data()) || vm.form.reportPriorArt.$dirty;
        }

        function validate() {
            return vm.form.$validate();
        }

        function getFormData() {
            var delta = inlineEdit.createDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);
            return {
                attributesDelta: delta,
                attributes: vm.gridOptions.dataSource.data(),
                reportPriorArt: vm.formData.reportPriorArt
            };
        }

        function convertToSaveModel(dataItem) {
            var updatedRecord = {
                id: dataItem.id,
                countryCode: dataItem.countryCode,
                typeId: dataItem.typeId,
                valueId: dataItem.valueId
            };
            return updatedRecord;
        }
    });