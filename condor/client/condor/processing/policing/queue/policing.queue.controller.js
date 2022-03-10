angular.module('inprotech.processing.policing')
    .controller('PolicingQueueController',
        function ($scope, $interval, kendoGridBuilder, policingQueueService, viewData, queueType,
            menuSelection, notificationService, modalService, refreshInterval, BulkMenuOperations) {
            'use strict';

            var vm = this;
            var service;
            var context;
            var bulkMenuOperations;
            vm.$onInit = onInit;

            function onInit() {
                service = policingQueueService;
                context = 'policingQueue';
                vm.nextRunTime = null;
                bulkMenuOperations = new BulkMenuOperations(context);
                vm.combinedFieldTemplate = combinedFieldTemplate;
                vm.prepareDataSource = prepareDataSource;

                service.config({
                    permissions: {
                        canAdminister: viewData.canAdminister,
                        canMaintainWorkflow: viewData.canMaintainWorkflow
                    }
                });
                vm.summary = viewData.summary;

                $scope.$on('nextRunTime', function (event, val) {
                    vm.nextRunTime = val;
                });
    
                vm.filterOptions = {
                    state: queueType
                };
    
                vm.actions = [{
                    id: 'Release',
                    icon: 'cpa-icon cpa-icon-play',
                    text: 'policing.queue.actions.release',
                    enabled: anySelected,
                    click: function () {
                        service.releaseSelected(getSelectedRecords()).then(function () {
                            notificationService.success('policing.queue.policingQueueItemsUpdated');
                            readData();
                        });
                    }
                }, {
                    id: 'Hold',
                    icon: 'cpa-icon cpa-icon-pause',
                    text: 'policing.queue.actions.hold',
                    enabled: anySelected,
                    click: function () {
                        service.holdSelected(getSelectedRecords()).then(function () {
                            notificationService.success('policing.queue.policingQueueItemsUpdated');
                            readData();
                        });
                    }
                }, {
                    id: 'Delete',
                    icon: 'cpa-icon cpa-icon-trash',
                    text: 'policing.queue.actions.delete',
                    enabled: anySelected,
                    click: function () {
                        notificationService.confirmDelete({
                            message: 'modal.confirmDelete.message'
                        }).then(function () {
                            service.deleteSelected(getSelectedRecords()).then(function () {
                                notificationService.success('policing.queue.policingQueueItemsUpdated');
                                readData();
                            });
                        });
                    }
                }, {
                    id: 'ReleaseAll',
                    icon: 'cpa-icon cpa-icon-play',
                    text: 'policing.queue.actions.releaseAll',
                    enabled: nothingSelected,
                    click: function () {
                        callServiceForAll(service.releaseAll);
                    }
                }, {
                    id: 'HoldAll',
                    icon: 'cpa-icon cpa-icon-pause',
                    text: 'policing.queue.actions.holdAll',
                    enabled: nothingSelected,
                    click: function () {
                        callServiceForAll(service.holdAll);
                    }
                }, {
                    id: 'DeleteAll',
                    icon: 'cpa-icon cpa-icon-trash',
                    text: 'policing.queue.actions.deleteAll',
                    enabled: nothingSelected,
                    click: function () {
                        callServiceForAll(service.deleteAll);
                    }
                }, {
                    id: 'EditNextRunTime',
                    icon: 'cpa-icon cpa-icon-pencil-square-o',
                    text: 'policing.queue.actions.scheduleNextRunTime',
                    enabled: anySelected,
                    click: openNextRunTime
                }];
            }

            function readData() {
                autoRefreshTimer.stop();
                bulkMenuOperations.clearSelectedItemsArray();
                vm.gridOptions.search()
                    .then(null, function () {
                        vm.refreshState = false;
                    }).always(function () {
                        autoRefreshTimer.autoSet();
                    });
            }            

            function openNextRunTime() {
                vm.nextRunTime = null;
                $scope.currentDate = null;
                if (getSelectedRecords().length == 1) {
                    $scope.currentDate = _.first(_.pluck(getSelectedRecords(), 'nextScheduled'));
                }
                modalService.open('NextRunTime', $scope, {})
                    .then(function () {
                        if (vm.nextRunTime) {
                            service.editNextRunTime(vm.nextRunTime, getSelectedRecords()).then(function () {
                                notificationService.success('policing.queue.policingQueueItemsUpdated');
                                readData();
                            });
                        }
                    });
            }            

            vm.selectionActions = {
                selectAll: function (val) {
                    bulkMenuOperations.selectAll(vm.gridOptions.data(), val);
                },
                selectThisPage: function (val) {
                    bulkMenuOperations.selectPage(vm.gridOptions.data(), val);
                },
                clearSelection: function () {
                    bulkMenuOperations.clearAll(vm.gridOptions.data());
                }
            };

            vm.menuInitialised = function () {
                bulkMenuOperations.initialiseMenuForPaging(vm.gridOptions.pageable.pageSize);
            };

            var refreshAfterHold = false;
            vm.refreshState = true;
            vm.refreshInterval = refreshInterval;
            var interval;

            var autoRefreshTimer = {
                start: function () {
                    interval = $interval(function () {
                        if (vm.refreshState) {
                            readData();
                        }
                    }, vm.refreshInterval * 1000);
                },

                stop: function () {
                    $interval.cancel(interval);
                },

                autoSet: function () {
                    if (vm.refreshState) {
                        autoRefreshTimer.start();
                    } else {
                        autoRefreshTimer.stop();
                    }
                }
            }

            vm.autoRefreshChange = function () {
                autoRefreshTimer.autoSet();
            };

            autoRefreshTimer.autoSet();

            $scope.$on('$destroy', function () {
                autoRefreshTimer.stop();
            });

            $scope.$on('FilterPopUp', function (event, isOpen) {
                setRefreshOnHold(isOpen);
                //$scope.$apply();
            });

            $scope.$on('RefreshOnHold', function (event, onHold) {
                setRefreshOnHold(onHold);
            });

            vm.selectionChange = function (dataItem) {
                bulkMenuOperations.singleSelectionChange(vm.gridOptions.data(), dataItem);
                setRefreshOnHold(bulkMenuOperations.anySelected());
            };

            vm.caseRefUrl = function (caseRef) {
                return '../default.aspx?caseref=' + encodeURIComponent(caseRef);
            }

            function setRefreshOnHold(onHold) {
                if (onHold && vm.refreshState || !onHold && refreshAfterHold) {
                    refreshAfterHold = onHold;
                    vm.refreshState = !onHold;
                    autoRefreshTimer.autoSet();
                }
            }

            vm.subheading = allRequestTypes() ? 'total' : queueType;

            vm.hasErrors = false;

            function allRequestTypes() {
                return !queueType || queueType === 'all';
            }

            vm.gridOptions = kendoGridBuilder.buildOptions($scope, {
                id: 'queue',
                filterOptions: {
                    keepFiltersAfterRead: true,
                    sendExplicitValues: true
                },
                pageable: {
                    pageSize: 50
                },
                scrollable: false,
                autoBind: true,
                resizable: false,
                reorderable: false,
                navigatable: true,
                selectable: true,
                onSelect: function () {
                    vm.gridOptions.clickHyperlinkedCell();
                },
                read: function (queryParams) {
                    return service.get(queueType, queryParams).then(function (data) {
                        return vm.prepareDataSource(data);
                    });
                },
                readFilterMetadata: function (column) {
                    return service.getColumnFilterData(column, queueType, vm.gridOptions.getCurrentFilters().filters, this.getFiltersExcept(column));
                },
                hideExpand: true,
                columns: getColumns(),
                detailTemplate: '#if(status ===\'in-error\') {# <ip-queue-errorview data-parent="dataItem" style="width:90%"></ip-queue-errorview> #}#',
                onPageSizeChanged: onPageSizeChanged,
                onDataCreated: onDataCreated,
                onDataBound: function () {
                    vm.gridOptions.expandAll('queue');
                    vm.summary = service.getCachedSummary();
                    vm.hasErrors = _.some(vm.gridOptions.data(), {
                        status: 'in-error'
                    });
                }
            });

            function translatedFieldTemplate(fieldName) {
                return '<span ng-bind="dataItem.' + fieldName + ' | translate"></span>';
            }

            function combinedFieldTemplate(fieldValue, fieldInBrackets) {
                if (fieldValue && fieldInBrackets)
                    return fieldValue + " (" + fieldInBrackets + ")";
                if (fieldValue)
                    return fieldValue;
                if (fieldInBrackets)
                    return fieldInBrackets
                return "";
            }

            function onDataCreated() {
                bulkMenuOperations.selectionChange(vm.gridOptions.data());
            }

            function onPageSizeChanged() {
                menuSelection.updatePaginationInfo(context, true, vm.gridOptions.pageable.pageSize);
            }

            function getSelectedRecords() {
                return bulkMenuOperations.selectedRecords();
            }

            function anySelected() {
                return bulkMenuOperations.anySelected();
            }

            function nothingSelected() {
                return !anySelected();
            }

            function callServiceForAll(serviceFunc) {
                notificationService.confirm({
                    message: 'modal.confirmSelectionAll.message'
                }).then(function () {
                    serviceFunc(queueType, vm.gridOptions.getCurrentFilters()).then(function () {
                        notificationService.success('policing.queue.policingQueueItemsUpdated');
                        readData();
                    });
                });
            }

            function getColumns() {
                var columns = [];
                if (viewData.canAdminister) {
                    columns.push({
                        field: 'bulkMenu',
                        headerTemplate: '<div data-bulk-actions-menu is-full-selection-possible="true" data-actions="vm.actions" data-context="policingQueue" data-on-clear="vm.selectionActions.clearSelection();" data-on-select-this-page="vm.selectionActions.selectThisPage(val)" data-on-select-all="vm.selectionActions.selectAll(val)" data-on-update-values="vm.updateValues()" data-initialised="vm.menuInitialised()"></div>',
                        template: '<ip-checkbox ng-model="dataItem.selected" data-ng-id="{{dataItem.id}}" ng-change="vm.selectionChange(dataItem)">',
                        sortable: false,
                        width: '20px',
                        locked: true
                    });
                }

                if (allRequestTypes() || queueType === 'requires-attention') {
                    columns.push({
                        field: 'name',
                        headerTemplate: '<ip-icon-button id="queueErrorIcon" class="btn-no-bg" ng-class="vm.hasErrors ? \'policing-exclamation-square\' : \'policing-exclamation-square-noerror\'" button-icon="exclamation-square" type="button" style="cursor:default"></ip-icon-button>',
                        template: '#if(status ===\'in-error\') {# <ip-icon-button class="btn-no-bg expand-btn error" button-icon="exclamation-square expand-btn" type="button" ip-tooltip="{{::\'policing.queue.expandErrorIconTooltip\' | translate }}" data-placement="top"></ip-icon-button> #}#',
                        sortable: false,
                        width: '30px',
                        locked: true
                    });
                }

                return _.union(columns, [{
                    title: 'policing.queue.status',
                    field: 'status',
                    sortable: false,
                    width: '150px',
                    filterable: true,
                    template: translatedFieldTemplate('status')
                }, {
                    title: 'policing.queue.requestDateTime',
                    field: 'requested',
                    sortable: false,
                    width: '200px',
                    template: '<ip-date-time model="dataItem.requested"></ip-date-time>'
                }, {
                    title: 'policing.queue.user',
                    field: 'user',
                    sortable: false,
                    width: '100px',
                    filterable: true
                }, {
                    title: 'policing.queue.caseReference',
                    field: 'caseReference',
                    sortable: false,
                    width: '120px',
                    template: function () {
                        return '<ip-ie-only-url data-url="vm.caseRefUrl(dataItem.caseReference)" ng-class="pointerCursor" data-text="dataItem.caseReference"></ip-ie-only-url>';
                    },
                    filterable: true
                }, {
                    title: 'policing.queue.typeOfRequest',
                    field: 'typeOfRequest',
                    sortable: false,
                    width: '150px',
                    filterable: true,
                    template: translatedFieldTemplate('typeOfRequest')
                }, {
                    title: 'policing.queue.event',
                    sortable: false,
                    width: '250px',
                    template: function (dataItem) {
                        if (viewData.canMaintainWorkflow && dataItem.hasEventControl) {
                            return '<a href="#/configuration/rules/workflows/' + encodeURIComponent(dataItem.criteriaId) + '/eventcontrol/' + encodeURIComponent(dataItem.eventId) + '">{{ vm.combinedFieldTemplate(dataItem.eventDescription,dataItem.eventId) }}</a>';
                        } else {
                            return '<span ng-if="dataItem.eventId">{{ vm.combinedFieldTemplate(dataItem.eventDescription,dataItem.eventId) }}</span>';
                        }
                    }
                }, {
                    title: 'policing.queue.cycle',
                    field: 'cycle',
                    sortable: false,
                    width: '80px'
                }, {
                    title: 'policing.queue.actionName',
                    field: 'actionName',
                    sortable: false,
                    width: '100px'
                }, {
                    title: 'policing.queue.criteria',
                    sortable: false,
                    width: '250px',
                    template: function (dataItem) {
                        if (dataItem.criteriaId) {
                            if (viewData.canMaintainWorkflow) {
                                return '<a href="#/configuration/rules/workflows/' + dataItem.criteriaId + '">{{ vm.combinedFieldTemplate(dataItem.criteriaDescription,dataItem.criteriaId) }}</a>';
                            } else {
                                return '<span>{{ vm.combinedFieldTemplate(dataItem.criteriaDescription,dataItem.criteriaId) }}</span>';
                            }
                        } else return '';
                    }
                }, {
                    title: 'policing.queue.nextRunTime',
                    field: 'nextScheduled',
                    sortable: false,
                    width: '100px',
                    template: '<ip-date-time model="dataItem.nextScheduled"></ip-date-time>'
                }, {
                    title: 'policing.queue.jurisdiction',
                    field: 'jurisdiction',
                    sortable: false,
                    width: '100px'
                }, {
                    title: 'policing.queue.propertyType',
                    field: 'propertyName',
                    sortable: false,
                    width: '100px'
                }, {
                    title: 'policing.queue.policingName',
                    field: 'policingName',
                    sortable: false,
                    width: '160px'
                }]);
            }

            function prepareDataSource(dataSource) {
                if (dataSource) {
                    dataSource.data.forEach(function (data) {
                        if (!data.id) {
                            data.id = data.requestId;
                        }
                    }, this);
                }
                return dataSource;
            }
        });