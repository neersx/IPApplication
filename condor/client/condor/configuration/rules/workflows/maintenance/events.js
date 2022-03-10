angular.module('inprotech.configuration.rules.workflows').directive(
    'ipWorkflowsMaintenanceEvents',
    function () {
        'use strict';

        return {
            restrict: 'E',
            templateUrl: 'condor/configuration/rules/workflows/maintenance/events.html',
            scope: {},
            controller: 'ipWorkflowsMaintenanceEventsController',
            controllerAs: 'vm',
            bindToController: {
                topic: '='
            }
        };
    }).controller('ipWorkflowsMaintenanceEventsController', function (
        $scope, $state,
        kendoGridBuilder, hotkeys,
        workflowsMaintenanceEventsService, sharedService,
        menuSelection, modalService,
        notificationService, picklistService,
        BulkMenuOperations, bus, pagerHelperService, $timeout) {
        'use strict';

        var vm = this;
        var service = workflowsMaintenanceEventsService;
        var maintenanceEventsPrefix = 'workflows.maintenance.events.';
        var _isPagingToFoundEvent = false;
        var _foundEvents = [];
        var bulkMenuOperations;

        vm.$onInit = onInit;

        function onInit() {            
            vm.criteriaId = vm.topic && vm.topic.params.criteriaId;
            vm.canEdit = vm.topic && vm.topic.params.canEdit;
            vm.shared = sharedService;
            vm.eventMatches = null;
            vm.gridOptions = buildGridOptions();
            vm.getEvents = getEvents;
            vm.searchEvents = searchEvents;
            vm.onClickAdd = selectEventToAdd;
            vm.addEventDirectly = addEventDirectly;
            vm.canAddEventDirectly = canAddEventDirectly;
            vm.menu = buildMenu();
            vm.eventControlName = { itemName: 'Event Control' };
            bulkMenuOperations = new BulkMenuOperations(vm.menu.context);
            vm.topic.initializeShortcuts = initShortcuts;
            vm.prepareDataSource = prepareDataSource;
            service.resetNewlyAddedEventIds();
        }

        $scope.$watch('vm.shared.selectedEventInDetail', function () {
            vm.searchEvents(true);
        });  
        
        function buildGridOptions() {
            var columns = [{
                fixed: true,
                width: '35px',
                template: '<ip-inheritance-icon inheritance-level="{{::dataItem.inheritanceLevel}}"></ip-inheritance-icon>',
                oneTimeBinding: true
            }, {
                title: 'workflows.common.eventNo',
                field: 'eventNo',
                template: '<a ui-sref="workflows.details.eventcontrol({eventId: {{::dataItem.eventNo}}})">{{::dataItem.eventNo}}</a>',
                oneTimeBinding: true
            }, {
                title: 'workflows.common.eventDescription',
                field: 'description',
                template: '<a ui-sref="workflows.details.eventcontrol({eventId: {{::dataItem.eventNo}}})">{{::dataItem.description}}</a>',
                oneTimeBinding: true
            }, {
                title: maintenanceEventsPrefix + 'eventCode',
                field: 'eventCode',
                template: '{{::dataItem.eventCode}}',
                oneTimeBinding: true
            }, {
                title: maintenanceEventsPrefix + 'importance',
                field: 'importance',
                filterable: true,
                template: '{{::dataItem.importance}}',
                oneTimeBinding: true
            }, {
                title: maintenanceEventsPrefix + 'maxCycles',
                field: 'maxCycles',
                template: '{{::dataItem.maxCycles}}',
                oneTimeBinding: true
            }];

            if (vm.topic.params.canEdit) {
                columns.unshift({
                    headerTemplate: '<bulk-actions-menu data-context="events" data-actions="vm.menu.items" is-full-selection-possible="false" data-on-select-this-page="vm.menu.selectPage(val)" data-on-clear="vm.menu.clearAll()" data-initialised="vm.menuInitialised()">',
                    template: '<ip-checkbox ng-model="dataItem.selected" ng-change="vm.menu.selectionChange(dataItem)">',
                    width: '35px',
                    fixed: true,
                    locked: true
                });
            }

            vm.menuInitialised = function () {
                bulkMenuOperations.initialiseMenuForPaging(vm.gridOptions.pageable.pageSize);
            };

            var firstLoad = true;
            return kendoGridBuilder.buildOptions($scope, {
                id: 'eventResults',
                autoBind: true,
                pageable: {
                    pageSize: 100,
                    pageSizes: [10, 20, 50, 100, 500]
                },
                sortable: false,
                rowDraggable: vm.topic.params.canEdit,
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{saved: dataItem.added, found: dataItem.isFound, bold: dataItem.isDirectMatch}"',
                selectable: true,
                reorderable: false,
                topicItemNumberKey: vm.topic.key,
                read: function (queryParams) {
                    return vm.getEvents(queryParams)
                        .then(function (data) {
                            if (_isPagingToFoundEvent) {
                                $timeout(function () {
                                    markFoundEvents(_foundEvents);
                                });
                                _isPagingToFoundEvent = false;
                            } else {
                                vm.searchEvents(firstLoad);
                                firstLoad = false;
                            }
                            return vm.prepareDataSource(data);
                        });
                },
                readFilterMetadata: function (column) {
                    return service.getEventFilterMetadata(vm.criteriaId, column.field);
                },
                onDataCreated: function () {
                    bulkMenuOperations.selectionChange(vm.gridOptions.data());
                },
                onDropCompleted: function (args) {
                    var sourceId = args.source.eventNo;
                    var targetId = args.target.eventNo;
                    var insertBefore = args.insertBefore;

                    service.reorderEvent(vm.criteriaId, sourceId, targetId, insertBefore).then(function (data) {
                        service.refreshEventIds(vm.gridOptions.data());
                        return service.confirmReorderDescendants(vm.criteriaId, sourceId, targetId, data.prevTargetId, data.nextTargetId, insertBefore, $scope);
                    });
                },
                columns: columns
            });
        }

        function selectEventToAdd() {
            picklistService.openModal($scope, {
                type: 'events',
                canMaintain: true,
                searchValue: getEventDescriptionIfNoMatches(),
                size: 'xl',
                columnMenu: true,
                displayName: 'picklist.event.Type'
            })
                .then(function (selectedEvent) {
                    if (eventExists(selectedEvent.key)) {
                        notificationService.alert({
                            title: 'modal.unableToComplete',
                            message: 'modal.workflowEventExists.message'
                        });
                    } else {
                        addEventToCriteria(selectedEvent);
                    }
                });
        }

        function addEventDirectly() {
            if (vm.shared.selectedEventInDetail && vm.shared.selectedEventInDetail.key != null && vm.shared.selectedEventInDetail.key !== '') {
                addEventToCriteria(vm.shared.selectedEventInDetail);
            }
        }

        function addEventToCriteria(selectedEvent) {
            var selectedRow = vm.gridOptions.getSelectedRow();
            service.addEventWorkflow(vm.criteriaId, selectedEvent.key, $scope)
                .then(function (inherit) {
                    var insertAfterEventId = selectedRow != null ? selectedRow.eventNo : null;
                    return service.addEvent(vm.criteriaId, selectedEvent.key, insertAfterEventId, inherit);
                })
                .then(function (addedEvent) {
                    service.addEventId(addedEvent, selectedRow);
                    addedEvent.added = true;

                    bus.channel('gridRefresh.eventResults').broadcast();

                    if (vm.shared.selectedEventInDetail) {
                        $timeout(function () {
                            scrollToMatchedEvents();
                        });
                    }
                });
        }

        function startDeleteWorkflow() {
            var selectedEvents = getSelectedEvents();

            if (!selectedEvents.length) {
                return;
            }

            service.confirmDeleteWorkflow($scope, vm.criteriaId, selectedEvents)
                .then(function (confirmation) {
                    return service.deleteEvents(vm.criteriaId, selectedEvents, Boolean(confirmation.applyToDescendants));
                })
                .then(deleteFromGrid);
        }

        function createEntry() {
            var selectedEvents = _.map(bulkMenuOperations.selectedRecords(), function (event) {
                return {
                    eventNo: event.eventNo,
                    description: event.description
                };
            });

            if (!selectedEvents.length) {
                return;
            }

            service.showCreateEntryModal($scope, vm.criteriaId, selectedEvents)
                .then(function (addedEntry) {
                    if (addedEntry) {
                        $state.reload($state.current.name);
                    }
                });
        }

        function getSelectedEvents() {
            return _.pluck(bulkMenuOperations.selectedRecords(), 'eventNo');
        }

        function getEventDescriptionIfNoMatches() {
            if (canAddEventDirectly()) {
                return vm.shared.selectedEventInDetail.value;
            }
            return null;
        }

        function deleteFromGrid() {
            var deleteRows = bulkMenuOperations.selectedRecords();

            _.each(deleteRows, function (row) {
                row.deleted = row.selected;
            });
            vm.gridOptions.removeDeletedRows();
            raiseDataCountEvent();
            service.removeEventIds(deleteRows);
            if (vm.eventMatches) {
                vm.eventMatches = _.difference(vm.eventMatches, deleteRows.map(function (r) {
                    return r.eventNo;
                }));
            }
            bulkMenuOperations.clearAll(vm.gridOptions.dataSource.data());
            notificationService.success();
        }

        function raiseDataCountEvent() {
            var data = {
                isSubSection: false,
                key: vm.topic.key,
                total: vm.gridOptions.dataSource._total
            };
            $scope.$emit('topicItemNumbers', data);
        }

        function buildMenu() {
            return {
                context: 'events',
                items: [{
                    id: 'delete',
                    text: 'bulkactionsmenu.deleteAll',
                    enabled: function () {
                        return bulkMenuOperations.anySelected(vm.gridOptions.data());
                    },
                    click: startDeleteWorkflow
                }, {
                    id: 'createEntry',
                    icon: 'cpa-icon cpa-icon-plus',
                    text: 'workflows.maintenance.events.createEntry',
                    enabled: function () {
                        return bulkMenuOperations.anySelected(vm.gridOptions.data());
                    },
                    click: createEntry
                }],
                clearAll: function () {
                    return bulkMenuOperations.clearAll(vm.gridOptions.data());
                },
                selectPage: function (val) {
                    return bulkMenuOperations.selectPage(vm.gridOptions.data(), val);
                },
                selectionChange: selectionChange
            };
        }

        function prepareDataSource(dataSource) {
            if (dataSource) {
                dataSource.data.forEach(function (data) {
                    if (!data.id) {
                        data.id = data.eventNo;
                    }
                    if (service.isEventNewlyAdded(data.eventNo)) {
                        data.added = true;
                    }
                }, this);
            }
            return dataSource;
        }

        function selectionChange(dataItem) {
            return bulkMenuOperations.singleSelectionChange(vm.gridOptions.data(), dataItem);
        }

        function clearFoundEvents() {
            _.each(vm.gridOptions.data(), function (ev) {
                ev.isFound = false;
                ev.isDirectMatch = false;
            });
            vm.eventMatches = null;
        }

        function getEvents(queryParams) {
            return service.getEvents(vm.criteriaId, queryParams);
        }

        function searchEvents(scrollToFound) {
            if (vm.shared.selectedEventInDetail && !isNaN(parseInt(vm.shared.selectedEventInDetail.key))) {
                service.searchEvents(vm.criteriaId, vm.shared.selectedEventInDetail.key)
                    .then(function (response) {
                        clearFoundEvents();
                        vm.eventMatches = response.data;

                        if (scrollToFound) {
                            if (!scrollToMatchedEvents()) {
                                return;
                            }
                        }

                        markFoundEvents(response.data);
                    });
            } else {
                clearFoundEvents();
            }
        }

        function scrollToMatchedEvents() {
            if (!vm.shared.selectedEventInDetail) {
                return false;
            }

            var allIds = service.eventIds();
            var directMatchPageIndex = pagerHelperService.getPageForId(allIds, vm.shared.selectedEventInDetail.key, vm.gridOptions.dataSource.take());
            if (directMatchPageIndex.page !== -1) {
                if (scrollTo(directMatchPageIndex.page, directMatchPageIndex.relativeRowIndex, vm.eventMatches)) {
                    return false; // don't mark events if paging required
                }
            } else {
                var firstIndirectIndex = _.min(vm.eventMatches.map(function (eId) {
                    return allIds.indexOf(eId);
                }));
                var indirectPageIndex = pagerHelperService.getPageForId(allIds, allIds[firstIndirectIndex], vm.gridOptions.dataSource.take());

                if (indirectPageIndex.page == -1) {
                    return false;
                }
                if (scrollTo(indirectPageIndex.page, indirectPageIndex.relativeRowIndex, vm.eventMatches)) {
                    return false; // don't mark events if paging required
                }
            }
            return true;
        }

        function scrollTo(page, rowIndex, foundEvents) {
            page = page === vm.gridOptions.dataSource.page() ? 'current' : page;
            bus.channel('grid.eventResults').broadcast({
                relativeIndex: rowIndex,
                pageIndex: page,
                unselectRow: true
            });

            if (page !== 'current') {
                _foundEvents = foundEvents;
                _isPagingToFoundEvent = true;
            } else {
                _isPagingToFoundEvent = false;
            }

            return _isPagingToFoundEvent;
        }

        function markFoundEvents(foundEvents) {
            var events = vm.gridOptions.data();
            var directMatch = _.find(events, function (ev) {
                return ev.eventNo === vm.shared.selectedEventInDetail.key;
            });
            if (directMatch) {
                directMatch.isDirectMatch = true;
            }

            _.each(foundEvents, function (eId) {
                var match = _.find(events, function (ev) {
                    return ev.eventNo === eId;
                });
                if (match) {
                    match.isFound = true;
                }
            });
        }

        function eventExists(newEventId) {
            var existingEvents = service.eventIds();
            return _.some(existingEvents, function (eventId) {
                return eventId === newEventId;
            });
        }

        function initShortcuts() {
            hotkeys.add({
                combo: 'alt+shift+i',
                description: 'shortcuts.add',
                callback: function () {
                    if (vm.topic.isActive) {
                        selectEventToAdd();
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

        function canAddEventDirectly() {
            if (!vm.shared.selectedEventInDetail) {
                return false;
            }
            return vm.canEdit && !eventExists(vm.shared.selectedEventInDetail.key);
        }
    });