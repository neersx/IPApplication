angular.module('inprotech.processing.policing')
    .controller('PolicingRequestLogController',
        function ($scope, $state, kendoGridBuilder, policingRequestLogService, viewData, policingLogId, dateService, notificationService) {
            'use strict';

            var vm = this;
            var service;

            vm.$onInit = onInit;

            function onInit() {
                service = policingRequestLogService;
                vm.policingLogId = policingLogId;

                vm.hasErrors = false;

                vm.showRequestLink = viewData.canViewOrMaintainRequests;
                service.displayCriteriaLinks = viewData.canMaintainWorkflow;

                vm.goToPolicingRequest = goToPolicingRequest;
                vm.deleteRow = deleteRow;

                vm.gridOptions = kendoGridBuilder.buildOptions($scope, {
                    id: 'requestlog',
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
                        return service.get(queryParams);
                    },
                    readFilterMetadata: function (column) {
                        return service.getColumnFilterData(column, this.getFiltersExcept(column));
                    },
                    hideExpand: true,
                    columns: getColumns(),
                    detailTemplate: '#if(status ===\'error\') {# <ip-request-logerror data="dataItem" style="width:90%"></ip-request-logerror> #}#',
                    scrollToFocus: true,
                    onDataBound: function () {
                        var gridData = vm.gridOptions.data();
                        vm.hasErrors = _.some(gridData, {
                            status: 'Error'
                        });

                        vm.gridOptions.expandAll('requestlog');
                        focusAndScrollToError(gridData);
                    }
                });
            }
            function focusAndScrollToError(gridData) {
                if (vm.policingLogId) {
                    var index = _.findIndex(gridData, function (data) {
                        return data.policingLogId == policingLogId;
                    });
                    if (index != -1) {
                        setTimeout(function () {
                            var fixedTopElem = $('ip-sticky-header:visible');
                            vm.gridOptions.selectRowAndScrollByIndex(fixedTopElem, index);
                        }, 100);
                    }
                }
            }

            function getColumns() {
                return [
                    {
                        headerTemplate: '<ip-icon-button id="requestErrorIcon" class="btn-no-bg"></ip-icon-button>',
                        template: '#if(hasErrors === true) {# <ip-icon-button class="btn-no-bg expand-btn error" button-icon="exclamation-square expand-btn" type="button"" data-placement="top"></ip-icon-button> #}# #if(canDelete === true) {# <ip-icon-button class="btn-no-bg" button-icon="trash-o" ip-tooltip="{{::\'Delete\' | translate }}" data-ng-click="vm.deleteRow(dataItem.policingLogId);"></ip-icon-button> #}#',
                        width: '10px',
                        sortable: false
                    }, {
                        title: 'policing.request.log.requestTitle',
                        field: 'policingName',
                        template: function () {
                            if (vm.showRequestLink) {
                                return '<a ng-click="vm.goToPolicingRequest()">{{:: dataItem.policingName }}</a>';
                            }
                            return '{{:: dataItem.policingName }}';
                        },
                        sortable: false,
                        width: '150px',
                        filterable: true
                    }, {
                        title: 'policing.request.log.status',
                        field: 'status',
                        template: '<span translate="policing.request.log.{{dataItem.status}}"></span>',
                        sortable: false,
                        width: '100px',
                        filterable: true
                    }, {
                        title: 'policing.request.log.startDateTime',
                        field: 'startDateTime',
                        template: '<ip-date-time model="dataItem.startDateTime"></ip-date-time>',
                        sortable: false,
                        filterable: {
                            type: 'date'
                        },
                        width: '170px'
                    }, {
                        title: 'policing.request.log.finishDateTime',
                        field: 'finishDateTime',
                        template: '<ip-date-time model="dataItem.finishDateTime"></ip-date-time>',
                        sortable: false,
                        width: '170px',
                        filterable: {
                            type: 'date'
                        }
                    }, {
                        title: 'policing.request.log.timeTaken',
                        sortable: false,
                        width: '100px',
                        template: '<span>{{ dataItem.timeTaken }}</span>'
                    }, {
                        title: 'policing.request.log.fromDate',
                        template: '<span>{{ dataItem.fromDate | date:"' + dateService.dateFormat + '" }}</span>',
                        sortable: false,
                        width: '70px'
                    }, {
                        title: 'policing.request.log.numberOfDays',
                        field: 'numberOfDays',
                        sortable: false,
                        width: '100px'
                    }, {
                        title: 'policing.request.log.failMessage',
                        field: 'failMessage',
                        sortable: false,
                        width: '140px'
                    }];
            }

            function goToPolicingRequest() {
                $state.go('policingRequestMaintenance');
            }

            function deleteRow(policingLogId) {
                notificationService.confirmDelete({
                    message: 'policing.request.log.deleteConfirmMessage'
                }).then(function () {
                    service.delete(policingLogId).then(function (response) {
                        if (response.result.status === 'success') {
                            notificationService.success();
                            vm.gridOptions.$read();
                        }
                    })
                });
            }
        });
