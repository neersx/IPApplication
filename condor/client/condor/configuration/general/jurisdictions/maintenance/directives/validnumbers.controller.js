angular.module('inprotech.configuration.general.jurisdictions')
    .controller('ValidNumbersController', function ($scope, kendoGridBuilder, jurisdictionValidNumbersService, dateService, modalService, dateHelper) {
        'use strict';

        var vm = this;
        var parentId;
        vm.$onInit = onInit;

        function onInit() {
            parentId = $scope.parentId;
            vm.onAddClick = onAddClick;
            vm.onEditClick = onEditClick;
            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getTopicFormData;
            vm.topic.hasError = angular.noop;
            vm.countryCode = $scope.parentId;
            vm.gridOptions = buildGridOptions();
            vm.topic.initialised = true;
        }

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'validNumbersGrid',
                topicItemNumberKey: vm.topic.key,
                autoBind: true,
                pageable: false,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted, deleted: dataItem.deleted, error: dataItem.error}" uib-tooltip="{{dataItem.errorMessage}}" tooltip-class="tooltip-error" data-tooltip-placement="left"',
                actions: vm.topic.canUpdate ? {
                    edit: {
                        onClick: 'vm.onEditClick(dataItem)'
                    },
                    delete: true
                } : null,
                autoGenerateRowTemplate: true,
                read: function (queryParams) {
                    if (vm.gridOptions.getQueryParams() !== null)
                        queryParams = vm.gridOptions.getQueryParams();
                    return jurisdictionValidNumbersService.search(queryParams, parentId).then(function (response) {
                        _.each(response, function (item) {
                            item.validFrom = dateHelper.convertForDatePicker(item.validFrom);
                        });
                        return response;
                    });
                },
                columns: [{
                    title: 'jurisdictions.maintenance.validNumbers.propertyType',
                    field: 'propertyTypeName',
                    sortable: true
                }, {
                    title: 'jurisdictions.maintenance.validNumbers.numberType',
                    field: 'numberTypeName',
                    sortable: true
                }, {
                    title: 'jurisdictions.maintenance.validNumbers.caseType',
                    field: 'caseTypeName',
                    sortable: true
                }, {
                    title: 'jurisdictions.maintenance.validNumbers.caseCategory',
                    field: 'caseCategoryName',
                    sortable: true
                }, {
                    title: 'jurisdictions.maintenance.validNumbers.subType',
                    field: 'subTypeName',
                    sortable: true
                }, {
                    title: 'jurisdictions.maintenance.validNumbers.validFrom',
                    field: 'validFrom',
                    template: '<span>{{ dataItem.validFrom | localeDate }}</span>'
                }, {
                    title: 'jurisdictions.maintenance.validNumbers.pattern',
                    field: 'pattern',
                    sortable: true
                }, {
                    title: 'jurisdictions.maintenance.validNumbers.warningFlag',
                    field: 'warningFlag',
                    sortable: true,
                    template: '<input ng-model="dataItem.warningFlag" type="checkbox" disabled="true" />'
                }, {
                    title: 'jurisdictions.maintenance.validNumbers.errorMessage',
                    field: 'displayMessage',
                    sortable: true
                }]
            });
        }

        function onAddClick() {
            openValidNumbersMaintenance('add').then(function (newData) {
                addItem(newData);
            });
        }

        function onEditClick(dataItem) {
            openValidNumbersMaintenance('edit', dataItem);
        }

        function addItem(newData) {
            vm.gridOptions.insertAfterSelectedRow(newData);
        }

        function openValidNumbersMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'ValidNumbersMaintenance',
                mode: mode,
                isAddAnother: false,
                controllerAs: 'vm',
                addItem: addItem,
                dataItem: dataItem,
                allItems: vm.gridOptions.dataSource.data(),
                parentId: parentId,
                jurisdiction: vm.topic.jurisdiction
            });
        }

        function isDirty() {
            var data = vm.gridOptions && vm.gridOptions.dataSource && vm.gridOptions.dataSource.data();
            var dirtyGrid = data && _.any(data, function (item) {
                return item.isAdded || item.deleted || item.isEdited;
            });
            return dirtyGrid;
        }

        function getTopicFormData() {
            return {
                validNumbersDelta: getDelta()
            };
        }

        function getDelta() {
            var added = getSaveModel(function (data) {
                return data.isAdded && !data.deleted;
            });

            var updated = getSaveModel(function (data) {
                return data.isEdited && !data.isAdded;
            });

            var deleted = getSaveModel(function (data) {
                return data.deleted;
            });

            return {
                added: added,
                updated: updated,
                deleted: deleted
            };
        }

        function getSaveModel(filter) {
            return _.chain(vm.gridOptions.dataSource.data())
                .filter(filter)
                .map(convertToSaveModel)
                .value();
        }

        function convertToSaveModel(dataItem) {
            var updatedRecord = {
                id: dataItem.id,
                propertyTypeCode: dataItem.propertyTypeCode,
                caseTypeCode: dataItem.caseTypeCode,
                subTypeCode: dataItem.subTypeCode,
                caseCategoryCode: dataItem.caseCategoryCode,
                numberTypeCode: dataItem.numberTypeCode,
                countryCode: $scope.parentId,
                pattern: dataItem.pattern,
                displayMessage: dataItem.displayMessage,
                additionalValidationId: dataItem.additionalValidationId,
                warningFlag: dataItem.warningFlag,
                validFrom: dataItem.validFrom
            };

            return updatedRecord;
        }        
    });