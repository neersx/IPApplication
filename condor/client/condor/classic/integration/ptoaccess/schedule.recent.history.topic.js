angular.module('Inprotech.Integration.PtoAccess')
    .component('ipScheduleRecentHistoryTopic', {
        template: '<ip-kendo-search-grid data-id="searchResults" data-grid-options="vm.gridOptions"></ip-kendo-search-grid>',
        bindings: {
            topic: '<'
        },
        controllerAs: 'vm',
        controller: function ($scope, $http, url, notificationService, $translate, kendoGridBuilder, modalService) {
            'use strict';

            var vm = this;
            vm.$onInit = onInit;

            function onInit() {
                _.extend(vm, vm.topic.params.viewData);
                vm.downloadIndex = downloadIndex;
                vm.onShowOnlyFailedClicked = onShowOnlyFailedClicked;
                vm.showErrorDetails = showErrorDetails;
                vm.showCancellationInfo = showCancellationInfo;
                vm.gridOptions = buildGridOptions();
                vm.showHideCorrelationIdColumn = showHideCorrelationIdColumn;
                vm.showHideIndexRetrievalColumn = showHideIndexRetrievalColumn;
                vm.isContinuousTypeSchedule = vm.schedule.type === 3;
            }

            function buildGridOptions() {
                return kendoGridBuilder.buildOptions($scope, {
                    id: 'searchResults',
                    pageable: {
                        pageSize: 50
                    },
                    sortable: false,
                    scrollable: false,
                    reorderable: false,
                    navigatable: true,
                    autoBind: true,
                    columns: buildColumns(),
                    read: function (queryParams) {
                        return getRecords(queryParams).then(function (data) {
                            vm.showHideCorrelationIdColumn(data.data);
                            vm.showHideIndexRetrievalColumn(data.data);

                            return data;
                        });
                    }
                });
            }

            function buildColumns() {
                var columns = [{
                    title: 'dataDownload.schedule.status',
                    width: '100px',
                    fixed: true,
                    template: function (dataItem) {
                        if (dataItem.status === 'Failed') {
                            return '<span class="text-red"><a href="javascript:void(0)" ng-click="vm.showErrorDetails(dataItem.id)">{{dataItem.status}}</a>&nbsp;<i class="cpa-icon cpa-icon-exclamation-circle" aria-hidden="true" title="Error"></i><span class="sr-only">Error</span></span>';
                        }
                        if (dataItem.status === 'Cancelled') {
                            return "<span title='{{ vm.showCancellationInfo(dataItem)'}}'>{{dataItem.status}}</span>";
                        }

                        return '<span>{{dataItem.status}}</span>';
                    }
                }, {
                    title: 'dataDownload.schedule.type',
                    template: function (dataItem) {
                        if (dataItem.type === 'Retry' && vm.isContinuousTypeSchedule) {
                            return '<span>' + $translate.instant('dataDownload.executionType.' + dataItem.type) + '</span><ip-inline-dialog data-content="' + $translate.instant('dataDownload.executionType.ContinuousRetryInfo') + '"></ip-inline-dialog>';
                        }
                        return '<span>' + $translate.instant('dataDownload.executionType.' + dataItem.type) + '</span>';
                    }
                }, {
                    title: 'dataDownload.schedule.started',
                    template: '<ip-date-time model="dataItem.started"></ip-date-time>'
                }, {
                    title: 'dataDownload.schedule.finished',
                    template: '<ip-date-time model="dataItem.finished"></ip-date-time>'
                }, {
                    title: 'dataDownload.schedule.cases',
                    template: function (dataItem) {
                        if (dataItem.status === 'Cancelled') {
                            return '<span> ------ </span>';
                        } else {
                            if (dataItem.casesIncluded === 0) {
                                return '<span>0</span>';
                            }
                            if (dataItem.casesIncluded > 0) {
                                return '<a ui-sref="inbox({se: {{dataItem.id}}, dataSource:\'{{vm.schedule.dataSource}}\' })">{{(dataItem.casesProcessed || 0)}}/{{dataItem.casesIncluded}} </a>';
                            }
                        }
                        return '<span />';
                    }
                }, {
                    title: 'dataDownload.schedule.documents',
                    template: function (dataItem) {
                        if (dataItem.status === 'Cancelled') {
                            return '<span> ------ </span>';
                        } else {
                            if (dataItem.documentsIncluded === 0) {
                                return '<span>0</span>';
                            }
                            if (dataItem.documentsIncluded > 0) {
                                return '<span>' + (dataItem.documentsProcessed || 0) + '/' + dataItem.documentsIncluded + '</span>';
                            }
                        }
                        return '<span />';
                    }
                }];

                columns.push({
                    title: 'dataDownload.schedule.correlation' + vm.schedule.dataSource,
                    field: 'correlationId',
                    hidden: true
                });

                columns.push({
                    title: ' ',
                    hidden: true,
                    template: function (dataItem) {
                        if (dataItem.allowsIndexRetrieval) {
                            return '<div><a id="btnRunNow_{{dataItem.id}}" data-ng-click="vm.downloadIndex(dataItem.id); $event.stopPropagation();"><i class="fa fa-cloud-download" />&nbsp;<span translate="dataDownload.schedule.review"></a></div';
                        }
                        return '<div />';
                    }
                });

                return columns;
            }

            function downloadIndex(id) {
                window.location = url.api('ptoaccess/schedules/' + vm.schedule.id + '/scheduleExecutions/' + id + '/raw-index');
            }

            function onShowOnlyFailedClicked(showOnlyFailed) {
                var status = showOnlyFailed ? 'Failed' : '';
                $http.get(url.api('ptoaccess/schedules/' + vm.schedule.id + '/scheduleExecutions?status=' + status))
                    .success(function (items) {
                        vm.scheduleExecutions = items;
                    });
            }

            function showErrorDetails(id) {
                $http.get(url.api('ptoaccess/scheduleExecutions/' + id + '/failures'))
                    .then(function (response) {
                        modalService.openModal({
                            id: 'ErrorDetails',
                            errorDetails: response.data.result,
                            controllerAs: 'vm'
                        });
                    });
            }

            function showCancellationInfo(dataItem) {
                if (dataItem.status !== 'Cancelled') {
                    return "";
                }

                return $translate.instant('tooltipCancellationInfo', {
                    user: dataItem.cancellationInfo.byUserName,
                    time: dataItem.cancellationInfo.cancelledOn
                });
            }

            function getRecords(queryParams) {
                return $http.get('api/ptoaccess/schedules/' + vm.schedule.id + '/scheduleExecutions/view', {
                    params: {
                        params: JSON.stringify(queryParams)
                    }
                })
                    .then(function (response) {
                        return response.data;
                    });
            }

            function showHideCorrelationIdColumn(data) {
                if (!vm.gridOptions.$widget) return;
                var hasCorrelationId = _.any(data, function (item) {
                    return item.correlationId;
                });

                var correlationIdColumn = _.find(vm.gridOptions.$widget.columns, function (c) {
                    return c.field === 'correlationId'
                });

                if (hasCorrelationId) {
                    vm.gridOptions.$widget.showColumn(correlationIdColumn);
                } else {
                    vm.gridOptions.$widget.hideColumn(correlationIdColumn);
                }
            }

            function showHideIndexRetrievalColumn(data) {
                if (!vm.gridOptions.$widget) return;
                var allowsIndexRetrieval = _.any(data, function (item) {
                    return item.allowsIndexRetrieval;
                });

                var indexRetrievalColumn = _.last(vm.gridOptions.$widget.columns);

                if (allowsIndexRetrieval) {
                    vm.gridOptions.$widget.showColumn(indexRetrievalColumn);
                } else {
                    vm.gridOptions.$widget.hideColumn(indexRetrievalColumn);
                }
            }
        }
    });