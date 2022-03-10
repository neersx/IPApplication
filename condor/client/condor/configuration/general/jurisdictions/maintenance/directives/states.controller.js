angular.module('inprotech.configuration.general.jurisdictions')
    .controller('StatesController', function ($scope, kendoGridBuilder, jurisdictionStatesService, jurisdictionMaintenanceService, inlineEdit, hotkeys, $translate) {
        'use strict';

        var vm = this;
        var parentId;
        vm.$onInit = onInit;

        function onInit() {
            parentId = $scope.parentId;
            vm.stateLabel = $scope.stateLabel || '';
            vm.gridOptions = buildGridOptions();
            vm.onAddClick = onAddClick;
            vm.stateCodeChange = stateCodeChange;
            vm.checkDuplicateError = checkDuplicateError;
            vm.getStateLabel = getStateLabel;
            vm.applyInUseError = applyInUseError;
            vm.getErrorType = getErrorType;

            _.extend(vm.topic, {
                getFormData: getFormData,
                hasError: hasError,
                isDirty: isDirty,
                validate: validate,
                initializeShortcuts: initShortcuts,
                setInUseError: setInUseError
            });
            vm.topic.initialised = true;
        }

        var createObj = inlineEdit.defineModel([
            'id',
            'countryId',
            'code',
            'name',
            'translatedName'
        ]);

        function getStateLabel() {
            return !vm.stateLabel.trim() ? $translate.instant('jurisdictions.maintenance.states.state') : vm.stateLabel;
        }

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'statesGrid',
                topicItemNumberKey: vm.topic.key,
                autoBind: true,
                pageable: false,
                sortable: false,
                read: function (queryParams) {
                    return jurisdictionStatesService.search(queryParams, parentId).then(function (data) {
                        return _.map(data, createObj);
                    });
                },
                autoGenerateRowTemplate: vm.topic.canUpdate,
                rowAttributes: 'ng-form="rowForm" ng-class="{error: rowForm.$invalid || dataItem.hasError() || dataItem.inUse, edited: dataItem.added || dataItem.isDirty(), deleted: dataItem.deleted}"' +
                    'uib-tooltip="{{vm.getErrorType(dataItem) | translate}} {{vm.getStateLabel()}}" tooltip-enable="{{dataItem.inUse || dataItem.error(\'duplicate\')}}" tooltip-class="tooltip-error" data-tooltip-placement="left"',
                actions: vm.topic.canUpdate ? {
                    delete: {
                        onClick: 'vm.checkDuplicateError(dataItem)'
                    }
                } : null,
                onDataCreated: function () {
                    vm.topic.setInUseError(jurisdictionMaintenanceService.getInUseItems('states'));
                },
                columns: [{
                    title: !vm.stateLabel.trim() ? 'jurisdictions.maintenance.states.state' : vm.stateLabel,
                    width: '10%',
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.code"></span>' +
                        '<ip-text-field ng-if="!dataItem.deleted" label="" focus-on-add ip-required name="stateCode" ng-maxlength="20" ng-model="dataItem.code" ng-change="vm.stateCodeChange(dataItem)" ng-disabled ="!dataItem.added && !dataItem.deleted "></ip-text-field>' : '<span ng-bind="dataItem.code"></span>'
                }, {
                    title: (!vm.stateLabel.trim() ? $translate.instant('jurisdictions.maintenance.states.state') : vm.stateLabel) + ' Name',
                    template: vm.topic.canUpdate ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.name"></span>' +
                        '<ip-text-field ng-if="!dataItem.deleted" label="" ip-required name="stateName" ng-maxlength="40" ng-model="dataItem.name" ng-change="vm.stateCodeChange(dataItem)"></ip-text-field>' : '<span ng-bind="dataItem.translatedName"></span>'
                }]
            });
        }

        function getErrorType(dataItem) {
            return dataItem.inUse === false ? 'field.errors.duplicate' : 'field.errors.inUse';
        }

        function stateCodeChange(dataItem) {
            vm.checkDuplicateError(dataItem);
        }

        function isDuplicate(allItems, dataItem) {
            return jurisdictionMaintenanceService.isDuplicated(allItems, dataItem, ['code']);
        }

        function onAddClick() {
            var insertIndex = vm.gridOptions.dataSource.total();
            var newState = createObj();
            newState.countryCode = vm.parentId;
            newState.id = -1;
            vm.gridOptions.insertRow(insertIndex, newState);
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
                stateDelta: delta
            };
        }

        function convertToSaveModel(dataItem) {
            var updatedRecord = {
                id: dataItem.id,
                countryId: parentId,
                code: dataItem.code,
                name: dataItem.name
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

        function setInUseError(inUseItems) {
            if (inUseItems !== null) {
                _.each(inUseItems, function (t) {
                    vm.applyInUseError(t);
                });
            }
        }

        function applyInUseError(inUseItem) {
            var item = _.find(vm.gridOptions.dataSource.data(), function (i) {
                return (i.id === inUseItem.id);
            });
            if (item)
                item.set("inUse", true);
            else
                item.set("inUse", false);
        }

        function checkDuplicateError(dataItem) {
            var itemsToBeValidated = _.filter(vm.gridOptions.dataSource.data(), function (item) {
                return !item.deleted;
            });
            if (isDuplicate(itemsToBeValidated, dataItem) && !dataItem.deleted) {
                dataItem.error('duplicate', true);
                dataItem.set("inUse", false);
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
        
    });