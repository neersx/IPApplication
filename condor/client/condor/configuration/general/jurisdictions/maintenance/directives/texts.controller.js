angular.module('inprotech.configuration.general.jurisdictions')
    .controller('TextsController', function ($scope, kendoGridBuilder, jurisdictionTextsService, jurisdictionMaintenanceService, inlineEdit, hotkeys) {
        'use strict';

        var vm = this;
        var parentId;
        var createObj = inlineEdit.defineModel([{
            name: 'textType',
            equals: function (objA, objB) {
                return objA.key === objB.key;
            }
        }, {
            name: 'propertyType',
            equals: function (objA, objB) {
                return objA.key === objB.key;
            }
        },
            'text',
            'sequenceId'
        ]);
        
        vm.$onInit = onInit;

        function onInit() {
            vm.formData = {}
            parentId = $scope.parentId;
            vm.gridOptions = buildGridOptions();
            vm.onAddClick = onAddClick;
            vm.extendPropertyTypePicklist = extendPropertyTypePicklist;
            vm.checkDuplicateError = checkDuplicateError;
            vm.onPicklistValueChange = onPicklistValueChange;            

            vm.topic.isDirty = isDirty;
            vm.topic.hasError = hasError;
            vm.topic.validate = validate;
            vm.topic.getFormData = getFormData;
            vm.topic.initializeShortcuts = initShortcuts;
            vm.topic.initialised = true;
        }

        function onAddClick() {
            var insertIndex = vm.gridOptions.dataSource.total();
            vm.gridOptions.insertRow(insertIndex, createObj());
        }

        function isDirty() {
            return inlineEdit.canSave(vm.gridOptions.dataSource.data());
        }

        function getFormData() {
            var delta = inlineEdit.createDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);
            return {
                textsDelta: delta
            };
        }

        function hasError() {
            return vm.form.$invalid || inlineEdit.hasError(vm.gridOptions.dataSource.data());
        }

        function convertToSaveModel(dataItem) {
            var updatedRecord = {
                countryCode: $scope.parentId,
                propertyType: dataItem.propertyType,
                textType: dataItem.textType,
                text: dataItem.text,
                sequenceId: dataItem.sequenceId
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

        function validate() {
            return vm.form.$validate();
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
            return jurisdictionMaintenanceService.isDuplicated(allItems, dataItem, ['textType', 'propertyType']);
        }

        function onPicklistValueChange(dataItem) {
            vm.checkDuplicateError(dataItem);
        }

        function extendPropertyTypePicklist(query) {
            var extended = angular.extend({}, query, {
                jurisdiction: $scope.parentId ? $scope.parentId : '',
                latency: 888
            });
            return extended;
        }

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'textsGrid',
                topicItemNumberKey: vm.topic.key,
                autoBind: true,
                pageable: false,
                sortable: false,
                read: function (queryParams) {
                    return jurisdictionTextsService.search(queryParams, parentId).then(function (data) {
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
                    'uib-tooltip="{{\'jurisdictions.maintenance.texts.duplicate\' | translate}}" tooltip-enable="dataItem.error(\'duplicate\')" tooltip-class="tooltip-error" data-tooltip-placement="left"',
                columns: [{
                    title: 'jurisdictions.maintenance.texts.textType',
                    width: "30%",
                    fixed: true,
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.textType.value"></span>' +
                        '<span ng-if="!dataItem.deleted && !dataItem.added" ng-bind="dataItem.textType.value" ></span>' +
                        '<ip-typeahead ng-if="!dataItem.deleted && dataItem.added" focus-on-add ip-required label="" name="textType" ng-class="{edited: vm.isDirty()}" ng-model="dataItem.textType" data-config="countryTexts" data-key-field="key" data-code-field="code" data-text-field="value" data-picklist-can-maintain="true" ng-change="vm.onPicklistValueChange(dataItem)"></ip-typeahead>' : '<span ng-bind="dataItem.textType.value"></span>'
                }, {
                    title: 'jurisdictions.maintenance.texts.propertyType',
                    width: "25%",
                    fixed: true,
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.propertyType.value"></span>' +
                        '<ip-typeahead ng-if="!dataItem.deleted" data-config="propertyType" label ="" name="propertyType" ng-model="dataItem.propertyType" ng-class="{edited: vm.isDirty()}" data-picklist-can-maintain="true" data-key-field="key" data-code-field="code" data-text-field="value" data-extend-query="vm.extendPropertyTypePicklist" ng-change="vm.onPicklistValueChange(dataItem)"></ip-typeahead>' : '<span ng-bind="dataItem.propertyType.value"></span>'
                }, {
                    title: 'jurisdictions.maintenance.texts.text',
                    width: "45%",
                    fixed: true,
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.text"></span>' +
                        '<ip-text-field multiline rows="3" ng-if="!dataItem.deleted" label="" name="text" ng-model="dataItem.text"></ip-text-field>' : '<span ng-bind="dataItem.text"></span>'
                }]
            });
        }
    });