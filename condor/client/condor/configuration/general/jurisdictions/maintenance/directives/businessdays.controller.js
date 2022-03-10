angular.module('inprotech.configuration.general.jurisdictions')
    .controller('BusinessDaysController', function ($scope, kendoGridBuilder, jurisdictionBusinessDaysService, dateService, hotkeys, dateHelper, modalService, BulkMenuOperations, notificationService, $translate, states) {
        'use strict';

        var vm = this;
        var parentId;
        var workDayFlag;
        var bulkMenuOperations;
        vm.$onInit = onInit;

        function onInit() {
            vm.context = 'countryholidays';
            parentId = $scope.parentId;
            workDayFlag = $scope.workDayFlag;
            vm.gridOptions = buildGridOptions();
            vm.formData = {};
            vm.onAddClick = onAddClick;
            vm.onEditClick = onEditClick;
            vm.OnDeleteClick = OnDeleteClick;
            vm.hasWorkDay = hasWorkDay;
            vm.topic.isDirty = isDirty;
            vm.topic.hasError = angular.noop;
            vm.topic.getFormData = getFormData;
            vm.topic.initializeShortcuts = initShortcuts;
            vm.menu = buildMenu();
            vm.allIds = [];
            vm.getSelectedItems = getSelectedItems;
            bulkMenuOperations = new BulkMenuOperations(vm.menu.context);

            initHolidayFlags();
            vm.topic.initialised = true;
        }

        function initHolidayFlags() {
            vm.holidays = [{
                day: 'Saturday',
                flag: 1,
                selected: hasWorkDay(1)
            }, {
                day: 'Sunday',
                flag: 2,
                selected: hasWorkDay(2)
            }, {
                day: 'Monday',
                flag: 4,
                selected: hasWorkDay(4)
            }, {
                day: 'Tuesday',
                flag: 8,
                selected: hasWorkDay(8)
            }, {
                day: 'Wednesday',
                flag: 16,
                selected: hasWorkDay(16)
            }, {
                day: 'Thursday',
                flag: 32,
                selected: hasWorkDay(32)
            }, {
                day: 'Friday',
                flag: 64,
                selected: hasWorkDay(64)
            }];
        }

        function hasWorkDay(flag) {
            return Boolean(workDayFlag & flag);
        }

        function buildGridOptions() {
            var columns = [{
                title: 'jurisdictions.maintenance.businessDays.date',
                field: 'holidayDate',
                template: '<ip-date model="dataItem.holidayDate"></ip-date>',
                sortable: true,
                oneTimeBinding: true
            }, {
                title: 'jurisdictions.maintenance.businessDays.dayOfWeek.title',
                field: 'dayOfWeek',
                sortable: true,
                oneTimeBinding: true
            }, {
                title: 'jurisdictions.maintenance.businessDays.holidayName',
                field: 'holiday',
                sortable: true,
                oneTimeBinding: true
            }];

            if (vm.topic.canUpdate) {
                columns.unshift({
                    headerTemplate: '<bulk-actions-menu data-context="' + vm.context + '" data-actions="vm.menu.items" is-full-selection-possible="false" data-on-select-this-page="vm.menu.selectPage(val)" data-on-clear="vm.menu.clearAll()" data-initialised="vm.menu.initialised()">',
                    template: '<ip-checkbox ng-model="dataItem.selected" ng-change="vm.menu.selectionChange(dataItem)">',
                    width: '35px',
                    fixed: true,
                    locked: true
                });
            }

            return kendoGridBuilder.buildOptions($scope, {
                id: 'holidaysGrid',
                autoBind: true,
                pageable: {
                    pageSize: 10,
                    pageSizes: [10, 20, 50, 100, 500]
                },
                read: function (queryParams) {
                    return jurisdictionBusinessDaysService.search(queryParams, parentId).then(function (response) {
                        _.each(response.data, function (item) {
                            item.holidayDate = dateHelper.convertForDatePicker(item.holidayDate);
                        });
                        vm.allIds = response.ids;
                        return response;
                    });
                },
                onDataCreated: function () {
                    bulkMenuOperations.selectionChange(vm.gridOptions.data());
                },
                selectable: true,
                reorderable: false,
                sortable: true,
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted, deleted: dataItem.deleted, error: dataItem.error}" uib-tooltip="{{dataItem.errorMessage}}" tooltip-class="tooltip-error" data-tooltip-placement="left"',
                columns: columns
            });
        }

        function buildMenu() {
            return {
                context: vm.context,
                items: [{
                    id: 'delete',
                    text: 'bulkactionsmenu.deleteAll',
                    enabled: anySelected,
                    click: OnDeleteClick
                },
                {
                    id: 'edit',
                    enabled: anySelected,
                    click: onEditClick,
                    maxSelection: 1
                }
                ],
                clearAll: function () {
                    return resetBulkMenu();
                },
                selectPage: function (val) {
                    return bulkMenuOperations.selectPage(vm.gridOptions.data(), val);
                },
                selectionChange: selectionChange,
                initialised: function () {
                    if (vm.gridOptions.data()) {
                        bulkMenuOperations.initialiseMenuForPaging(vm.gridOptions.pageable.pageSize);
                    }
                }
            };
        }

        function OnDeleteClick() {
            var selectedItems = vm.getSelectedItems();
            if (!selectedItems.length) {
                return;
            }

            notificationService.confirm({
                message: 'jurisdictions.maintenance.businessDays.confirmationOndelete'
            }).then(function () {
                jurisdictionBusinessDaysService.deleteCountryHolidays(selectedItems).then(function () {
                    notificationService.success($translate.instant('jurisdictions.maintenance.businessDays.changesSavedSuccessfully'));
                    vm.gridOptions.search();
                    resetBulkMenu();
                });
            });
        }

        function onAddClick() {
            vm.modelInstance = openBusinessdaysMaintenance('add').then(function () {
                vm.gridOptions.search();
            });
        }

        function onEditClick() {
            var dataItems = vm.getSelectedItems();
            if (dataItems.length != 1) {
                return;
            }
            vm.modelInstance = openBusinessdaysMaintenance('edit', dataItems[0].id).then(function () {
                vm.gridOptions.search();
            });
        }

        function anySelected() {
            return bulkMenuOperations.anySelected(vm.gridOptions.data());
        }

        function getSelectedItems() {
            return bulkMenuOperations.selectedRecords();
        }

        function selectionChange(dataItem) {
            return bulkMenuOperations.singleSelectionChange(vm.gridOptions.data(), dataItem);
        }

        function resetBulkMenu() {
            return bulkMenuOperations.clearAll(vm.gridOptions.data());
        }

        function openBusinessdaysMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'BusinessdaysMaintenance',
                mode: mode,
                isAddAnother: false,
                controllerAs: 'vm',
                addItem: angular.noop,
                dataItem: dataItem,
                allItems: vm.allIds,
                entityState: mode === 'add' ? states.adding : states.updating,
                parentId: parentId,
                refreshGrid: refreshGrid,
                jurisdiction: vm.topic.jurisdiction
            });
        }

        function refreshGrid() {
            vm.gridOptions.search();
            resetBulkMenu();
        }

        function isDirty() {
            return vm.form.$dirty;
        }

        function getFormData() {
            return {
                workDayFlag: getWorkDayFlag(),
                countryHolidaysDelta: null
            };
        }

        function getWorkDayFlag() {
            var selectedHolidays = _.filter(vm.holidays, function (holiday) {
                return holiday.selected;
            });
            var workDayFlag = 0;
            _.each(selectedHolidays, function (selected) {
                workDayFlag = workDayFlag + selected.flag;
            })
            return workDayFlag;
        }

        function initShortcuts() {
            if (vm.topic.canUpdate) {
                hotkeys.add({
                    combo: 'alt+shift+i',
                    description: 'shortcuts.add',
                    callback: onAddClick
                });

                hotkeys.add({
                    combo: 'alt+shift+del',
                    description: 'shortcuts.delete',
                    callback: OnDeleteClick
                });
            }
        }        
    });