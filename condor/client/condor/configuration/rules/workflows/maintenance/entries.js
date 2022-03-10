angular.module('inprotech.configuration.rules.workflows').directive('ipWorkflowsMaintenanceEntries', function () {
    'use strict';

    return {
        restrict: 'E',
        templateUrl: 'condor/configuration/rules/workflows/maintenance/entries.html',
        scope: {},
        controller: 'ipWorkflowsMaintenanceEntriesController',
        controllerAs: 'vm',
        bindToController: {
            topic: '='
        }
    };
}).controller('ipWorkflowsMaintenanceEntriesController', function ($scope, $state, kendoGridBuilder, workflowsMaintenanceEntriesService, sharedService, modalService, hotkeys, BulkMenuOperations, notificationService) {
    'use strict';

    var vm = this;
    var bulkOperation;
    var service;
    vm.$onInit = onInit;

    function onInit() {
        service = workflowsMaintenanceEntriesService;
        vm.criteriaId = vm.topic && vm.topic.params.criteriaId;
        vm.canEdit = vm.topic && vm.topic.params.canEdit;
        vm.shared = sharedService;
        if (sharedService.selectedEventInDetail) {
            vm.shared.selectedEventInDetail = sharedService.selectedEventInDetail;
        }
        vm.entryCount = null;
        vm.prepareToGoEntryControl = prepareToGoEntryControl;
        vm.onClickAdd = createEntry;
        vm.gridOptions = buildGridOptions();
        vm.menu = buildMenu();
        bulkOperation = new BulkMenuOperations(vm.menu.context);
        vm.topic.initializeShortcuts = initShortcuts;
        vm.prepareDataSource = prepareDataSource;
    }

    function buildMenu() {
        return {
            context: 'entries',
            items: [{
                id: 'delete',
                text: 'bulkactionsmenu.deleteAll',
                enabled: function () {
                    return bulkOperation.anySelected(vm.gridOptions.data());
                },
                click: startDeleteWorkflow
            }],
            clearAll: function () {
                return bulkOperation.clearAll(vm.gridOptions.data());
            },
            selectAll: function (val) {
                return bulkOperation.selectAll(vm.gridOptions.data(), val);
            },
            selectionChange: selectionChange,
            initialised: function () {
                if (vm.gridOptions.data()) {
                    bulkOperation.selectionChange(vm.gridOptions.data());
                }
            }
        };
    }

    function selectionChange() {
        return bulkOperation.selectionChange(vm.gridOptions.data());
    }

    function buildGridOptions() {
        var columns = [{
            fixed: true,
            width: '35px',
            template: '<ip-inheritance-icon inheritance-level="{{::dataItem.inheritanceLevel}}"></ip-inheritance-icon>',
            oneTimeBinding: true
        }, {
            title: 'workflows.maintenance.entries.entryDescription',
            field: 'description',
            template: '<a ui-sref="workflows.details.entrycontrol({entryId: dataItem.entryNo})" ng-click="vm.prepareToGoEntryControl()" class="display-spaces">{{::dataItem.description}}</a>',
            oneTimeBinding: true,
            width: "90%"
        }, {
            title: 'workflows.maintenance.entries.isSeparator',
            field: 'isSeparator',
            template: '<div class="center-block"><div class="cpa-icon-check" ng-if="dataItem.isSeparator"></div></div>',
            oneTimeBinding: true,
            width: '6%'
        }];
        if (vm.topic.params.canEdit) {
            columns.unshift({
                headerTemplate: '<bulk-actions-menu data-context="entries" data-actions="vm.menu.items" data-on-select-all="vm.menu.selectAll(val)" data-on-clear="vm.menu.clearAll()" data-initialised="vm.menu.initialised()">',
                template: '<ip-checkbox ng-model="dataItem.selected" ng-change="vm.menu.selectionChange(dataItem)">',
                width: '35px',
                fixed: true,
                locked: true
            });
        }
        return kendoGridBuilder.buildOptions($scope, {
            id: 'entriesResults',
            autoBind: true,
            pageable: false,
            sortable: false,
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{found: dataItem.isFound, saved: dataItem.added}"',
            rowDraggable: vm.topic.params.canEdit,
            selectable: true,
            reorderable: false,
            topicItemNumberKey: vm.topic.key,
            read: function (queryParams) {
                return vm.getEntries(queryParams)
                    .then(function (data) {
                        angular.element(".main-content-scrollable").scroll(function () {
                            angular.element(document.body).find("[data-role=popup]")
                                .kendoPopup("close");
                        });
                        vm.searchEntryEvents();
                        return data;
                    });
            },
            onDataCreated: function () {
                bulkOperation.selectionChange(vm.gridOptions.data());
            },
            onDropCompleted: function (args) {
                var sourceId = args.source.entryNo;
                var targetId = args.target.entryNo;
                var insertBefore = args.insertBefore;

                service.reorderEntry(vm.criteriaId, sourceId, targetId, insertBefore).then(function (data) {
                    args.source.added = true;
                    if (!data.descendents || !data.descendents.length) {
                        return null;
                    }

                    return modalService.open('InheritanceReorderConfirmation', $scope, {
                        items: function () {
                            return data.descendents;
                        }
                    }).then(function () {
                        return service.reorderDescendantsEntry(vm.criteriaId, sourceId, targetId, data.prevTargetId, data.nextTargetId, insertBefore);
                    });
                });
            },
            columns: columns
        });
    }

    vm.getEntries = function (queryParams) {
        return service.getEntries(vm.criteriaId, queryParams);
    };

    vm.searchEntryEvents = function () {
        if (vm.shared.selectedEventInDetail && !isNaN(parseInt(vm.shared.selectedEventInDetail.key))) {
            service.searchEntryEvents(vm.criteriaId, vm.shared.selectedEventInDetail.key)
                .then(function (response) {
                    clearFoundEntries();
                    var entries = vm.gridOptions.data();
                    vm.entryCount = response.data.length;
                    _.each(response.data, function (entryNo) {
                        entries.every(function (en) {
                            if (entryNo === en.entryNo) {
                                en.isFound = true;
                                return false;
                            }
                            return true;
                        });
                    });
                });
        } else {
            clearFoundEntries();
        }
    };

    $scope.$watch('vm.shared.selectedEventInDetail', function () {
        vm.searchEntryEvents();
    });

    $scope.$watch('vm.form.event.$invalid', function (invalid) {
        if (invalid) {
            clearFoundEntries();
        } else {
            vm.searchEntryEvents();
        }
    });

    function clearFoundEntries() {
        _.each(vm.gridOptions.data(), function (en) {
            en.isFound = false;
        });
        vm.entryCount = null;
    }

    function prepareToGoEntryControl() {
        service.entryIds(vm.gridOptions.data());
    }

    function createEntry() {
        var selectedRow = vm.gridOptions.getSelectedRow();
        var insertAfterEntryId = selectedRow != null ? selectedRow.entryNo : null;
        service.showCreateEntryModal($scope, vm.criteriaId, insertAfterEntryId)
            .then(function (addedEntry) {
                if (addedEntry) {
                    addedEntry.added = true;
                    addedEntry.id = addedEntry.entryNo;
                    var insertIndex;
                    if (selectedRow != null) {
                        insertIndex = vm.gridOptions.dataSource.indexOf(selectedRow) + 1;
                        vm.gridOptions.dataSource.insert(insertIndex, addedEntry);
                    } else {
                        vm.gridOptions.dataSource.add(addedEntry);
                        insertIndex = vm.gridOptions.data().length - 1;
                    }
                    raiseDataCountEvent();
                    vm.gridOptions.selectRowByIndex(insertIndex);
                    bulkOperation.selectionChange(vm.gridOptions.data());
                }
            });
    }

    function raiseDataCountEvent() {
        var data = {
            isSubSection: false,
            key: vm.topic.key,
            total: vm.gridOptions.dataSource._total
        };
        $scope.$emit('topicItemNumbers', data);
    }

    function startDeleteWorkflow() {
        var selectedEntries = getSelectedEntries();
        if (!selectedEntries.length) {
            return;
        }
        service.confirmDeleteWorkflow($scope, vm.criteriaId, selectedEntries)
            .then(function (confirmation) {
                return service.deleteEntries(vm.criteriaId, selectedEntries, Boolean(confirmation.applyToDescendants));
            })
            .then(deleteFromGrid);
    }

    function getSelectedEntries() {
        return _.pluck(_.where(vm.gridOptions.data(), {
            selected: true
        }), 'entryNo');
    }

    function deleteFromGrid() {
        var rows = vm.gridOptions.dataSource.data().toJSON();
        var newRows = _.filter(rows, function (row) {
            return !row.selected;
        });
        vm.gridOptions.dataSource.data(newRows);
        raiseDataCountEvent();
        bulkOperation.clearAll();

        notificationService.success();
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+i',
            description: 'shortcuts.add',
            callback: function () {
                if (vm.topic.isActive) {
                    createEntry();
                }
            }
        });

        hotkeys.add({
            combo: 'alt+shift+del',
            description: 'shortcuts.delete',
            callback: function () {
                if (vm.topic.isActive) {
                    startDeleteWorkflow();
                }
            }
        });
    }

    function prepareDataSource(dataSource) {
        if (dataSource) {
            dataSource.forEach(function (data) {
                if (!data.id) {
                    data.id = data.entryNo;
                }
            }, this);
        }
        return dataSource;
    }

});