angular.module('inprotech.processing.policing')
    .controller('PolicingErrorLogController',
        function ($scope, kendoGridBuilder, policingErrorLogService, viewData, menuSelection, notificationService, BulkMenuOperations) {
            'use strict';

            var vm = this;
            var permissions;
            var service;
            var context;
            var bulkMenuOperations;
            vm.$onInit = onInit;

            function onInit() {
                permissions = viewData.permissions;
                service = policingErrorLogService;
                context = 'policingErrorLog';
                bulkMenuOperations = new BulkMenuOperations(context);
                vm.prepareDataSource = prepareDataSource;
                vm.combinedFieldTemplate = combinedFieldTemplate;
                vm.gridOptions = kendoGridBuilder.buildOptions($scope, {
                    id: 'errorlog',
                    filterOptions: {
                        keepFiltersAfterRead: true,
                        sendExplicitValues: true
                    },
                    pageable: true,
                    scrollable: false,
                    autoBind: true,
                    resizable: false,
                    reorderable: false,
                    selectable: true,
                    navigatable: true,
                    onSelect: function () {
                        vm.gridOptions.clickHyperlinkedCell();
                    },
                    read: function (queryParams) {
                        return service.get(queryParams).then(function (data) {
                            return vm.prepareDataSource(data);
                        });
                    },
                    readFilterMetadata: function (column) {
                        return service.getColumnFilterData(column, this.getFiltersExcept(column));
                    },
                    columns: getColumns(),
                    onDataCreated: onDataCreated,
                    onPageSizeChanged: onPageSizeChanged
                });

                vm.actions = [{
                    id: 'delete',
                    enabled: anySelected,
                    click: function () {
                        notificationService.confirmDelete({
                            message: 'modal.confirmDelete.message'
                        }).then(function () {
                            service.delete(_.pluck(selectedItems(), 'policingErrorsId')).then(function (res) {
                                if (res.data.status == 'success') {
                                    notificationService.success();
                                    updateData();
                                }
                            });
                        });
                    }
                }];
            }

            var updateData = function () {
                vm.gridOptions.search().then(function () {
                    vm.selectionChange();
                });
            };

            vm.selectionActions = {
                selectThisPage: function (val) {
                    bulkMenuOperations.selectPage(selectableData(), val);
                },
                clearSelection: function () {
                    bulkMenuOperations.clearAll(selectableData());
                }
            };

            var selectedItems = function () {
                return bulkMenuOperations.selectedRecords();
            };

            vm.selectionChange = function (dataItem) {
                bulkMenuOperations.singleSelectionChange(selectableData(), dataItem);
            };

            vm.menuInitialised = function () {
                bulkMenuOperations.initialiseMenuForPaging(vm.gridOptions.pageable.pageSize);
            };

            vm.caseRefUrl = function (caseRef) {
                return '../default.aspx?caseref=' + encodeURIComponent(caseRef);
            }

            function anySelected() {
                return bulkMenuOperations.anySelected();
            }

            function selectableData() {
                return _.where(vm.gridOptions.data(), {
                    errorForInProgressItem: service.InprogressEnum.none
                });
            }

            function onDataCreated() {
                bulkMenuOperations.selectionChange(selectableData());
            }

            function onPageSizeChanged() {
                menuSelection.updatePaginationInfo(context, true, vm.gridOptions.pageable.pageSize);
            }

            function getColumns() {

                var columns = [];

                if (permissions.canAdminister) {
                    columns.push({
                        field: 'bulkMenu',
                        headerTemplate: '<div data-bulk-actions-menu is-full-selection-possible="false" data-actions="vm.actions" data-context="policingErrorLog" data-on-clear="vm.selectionActions.clearSelection();" data-on-select-this-page="vm.selectionActions.selectThisPage(val)" data-on-update-values="vm.updateValues()" data-initialised="vm.menuInitialised()"></div>',
                        template: function (dataItem) {
                            if (dataItem.errorForInProgressItem === service.InprogressEnum.none) {
                                return '<ip-checkbox ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)">';
                            } else {
                                return '';
                            }
                        },
                        sortable: false,
                        width: '20px',
                        locked: true
                    });
                }

                return _.union(columns, [{
                    headerTemplate: '<ip-icon-button id="inProgressErrorIcon" class="btn-no-bg policing-warning-icon" button-icon="exclamation-circle" type="button" style="cursor:default" ip-tooltip="{{::\'policing.errorLog.inProgressHeaderTooltip\' | translate }}" data-placement="top" tooltip-class="tooltip-warning-cpa"></ip-icon-button>',
                    template: function (dataItem) {
                        if (dataItem.errorForInProgressItem === service.InprogressEnum.queue) {
                            return '<ip-icon-button class="btn-no-bg policing-warning-icon" button-icon="exclamation-circle" type="button" style="cursor:default"  ip-tooltip="{{::\'policing.errorLog.inProgressQueueTooltip\' | translate }}" data-placement="top" tooltip-class="tooltip-warning-cpa"></ip-icon-button>';
                        } else if (dataItem.errorForInProgressItem === service.InprogressEnum.request) {
                            return '<ip-icon-button class="btn-no-bg policing-warning-icon" button-icon="exclamation-circle" type="button" style="cursor:default"  ip-tooltip="{{::\'policing.errorLog.inProgressRequestTooltip\' | translate }}" data-placement="top" tooltip-class="tooltip-warning-cpa"></ip-icon-button>';
                        } else {
                            return '';
                        }
                    },
                    sortable: false,
                    width: '20px',
                    locked: true
                }, {
                    title: 'policing.errorLog.date',
                    field: 'errorDate',
                    sortable: false,
                    width: '100px',
                    filterable: {
                        type: 'date'
                    },
                    template: '<ip-date-time model="dataItem.errorDate"></ip-date-time>'
                }, {
                    title: 'policing.errorLog.caseReference',
                    field: 'caseRef',
                    sortable: false,
                    template: function () {
                        return '<ip-ie-only-url data-url="vm.caseRefUrl(dataItem.caseRef)" ng-class="pointerCursor" data-text="dataItem.caseRef"></ip-ie-only-url>';
                    },
                    width: '100px',
                    filterable: {
                        type: 'text'
                    }
                }, {
                    title: 'policing.errorLog.message',
                    field: 'message',
                    sortable: false,
                    width: '250px',
                    filterable: {
                        type: 'text'
                    }
                }, {
                    title: 'policing.errorLog.event',
                    sortable: false,
                    width: '150px',
                    field: 'specificDescription-baseDescription',
                    filterable: {
                        type: 'text'
                    },
                    template: function (dataItem) {
                        if (permissions.canMaintainWorkflow && dataItem.hasEventControl) {
                            return '<a href="#/configuration/rules/workflows/{{dataItem.eventCriteriaNumber}}/eventcontrol/{{dataItem.eventNumber}}">{{ vm.combinedFieldTemplate(dataItem.eventDescription,dataItem.eventNumber) }}</a>';
                        } else {
                            return '<span ng-if="dataItem.eventNumber">{{ vm.combinedFieldTemplate(dataItem.eventDescription,dataItem.eventNumber) }}</span>';
                        }
                    }
                }, {
                    title: 'policing.errorLog.cycle',
                    field: 'eventCycle',
                    sortable: false,
                    width: '80px'
                }, {
                    title: 'policing.errorLog.criteria',
                    sortable: false,
                    width: '150px',
                    field: 'eventCriteriaDescription',
                    filterable: {
                        type: 'text'
                    },
                    template: function () {
                        if (permissions.canMaintainWorkflow) {
                            return '<a ng-if="dataItem.eventCriteriaNumber" href="#/configuration/rules/workflows/{{dataItem.eventCriteriaNumber}}">{{ vm.combinedFieldTemplate(dataItem.eventCriteriaDescription,dataItem.eventCriteriaNumber) }}</a>';
                        } else {
                            return '<span ng-if="dataItem.eventCriteriaNumber">{{ vm.combinedFieldTemplate(dataItem.eventCriteriaDescription,dataItem.eventCriteriaNumber) }}</a>';
                        }
                    }
                }]);
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

            function prepareDataSource(dataSource) {
                if (dataSource) {
                    dataSource.data.forEach(function (data) {
                        if (!data.id) {
                            data.id = data.policingErrorsId;
                        }
                    }, this);
                }
                return dataSource;
            }
        });