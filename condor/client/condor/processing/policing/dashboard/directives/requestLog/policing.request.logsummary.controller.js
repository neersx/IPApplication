(function () {
    'use strict';

    angular.module('inprotech.processing.policing')
        .controller('ipPolicingRequestLogsummaryController', ipPolicingRequestLogsummaryController);

    ipPolicingRequestLogsummaryController.$inject = ['$scope', '$state', '$interval', '$translate', 'kendoGridBuilder', 'policingRequestLogService', 'policingRequestService', 'modalService'];

    function ipPolicingRequestLogsummaryController($scope, $state, $interval, $translate, kendoGridBuilder, policingRequestLogService, policingRequestService, modalService) {
        var vm = this;
        var refreshInterval;
        var service;
        vm.$onInit = onInit;

        function onInit() {

            vm.showRequestLink = false;
            vm.openMaintenanceDialog = openMaintenanceDialog;
            vm.canCalculateAffectedCases = false;
            service = policingRequestService;

            vm.gridOptions = kendoGridBuilder.buildOptions($scope, {
                id: 'requestlog',
                filterOptions: {
                    keepFiltersAfterRead: true,
                    sendExplicitValues: true
                },
                pageable: false,
                scrollable: false,
                autoBind: true,
                resizable: false,
                reorderable: false,
                onSelect: function () {
                    vm.gridOptions.clickHyperlinkedCell();
                },
                read: function () {
                    return policingRequestLogService.recent()
                        .then(function (data) {
                            vm.showRequestLink = data.canViewOrMaintainRequests;
                            vm.canCalculateAffectedCases = data.canCalculateAffectedCases;
                            return data.requests;
                        });
                },
                hideExpand: true,
                columns: getColumns()
            });

            $scope.$on('$destroy', function () {
                if (reader) {
                    if (angular.isDefined(reader)) {
                        $interval.cancel(reader);
                        reader = undefined;
                    }
                }
            });
    
            refreshInterval = $state.params.rinterval || 30;

            var reader = $interval(function () {
                readData();
            }, refreshInterval * 1000); /* 5 minutes */
        }

        function readData() {
            vm.gridOptions.search();
        }

        function getColumns() {
            return [{
                title: 'policing.request.log.requestTitle',
                field: 'policingName',
                template: function (dataItem) {
                    if (vm.showRequestLink) {
                        return '<a ng-click="vm.goToPolicingRequest(' + dataItem.requestId + ')" href>{{:: dataItem.policingName }}</a>';
                    }
                    return '{{:: dataItem.policingName }}'
                },
                sortable: false,
                width: '100px'
            }, {
                title: 'policing.request.log.status',
                field: 'status',
                sortable: false,
                width: '100px',
                template: function (dataItem) {
                    var translatedStatus = $translate.instant('policing.request.log.' + dataItem.status);
                    return dataItem.hasErrors ? '<a href="#/policing-request-log?policingLogId=' + dataItem.policingLogId + '">' + translatedStatus + '</a>' : '<span>' + translatedStatus + '</span>';
                }
            }, {
                title: 'policing.request.log.startDateTime',
                field: 'startDateTime',
                template: '<ip-date-time model="dataItem.startDateTime"></ip-date-time>',
                sortable: false,
                width: '100px'
            }, {
                title: 'policing.request.log.finishDateTime',
                field: 'finishDateTime',
                template: '<ip-date-time model="dataItem.finishDateTime"></ip-date-time>',
                sortable: false,
                width: '100px'
            }, {
                title: 'policing.request.log.timeTaken',
                sortable: false,
                width: '100px',
                template: '<span>{{ dataItem.timeTaken }}</span>'
            }, {
                title: 'policing.request.log.failMessage',
                field: 'failMessage',
                sortable: false,
                width: '150px'
            }];
        }

        function openMaintenanceDialog(request) {
            modalService.open('PolicingRequestMaintain', $scope, {
                request: request,
                canCalculateAffectedCases: vm.canCalculateAffectedCases
            })
        }

        vm.goToPolicingRequest = function (requestId) {
            if (!requestId) { // this will be null for the requests who's req name itself has been changed, such reqs will still go to the manage requests pg where as others will go to the edit pg
                $state.go('policingRequestMaintenance');
            } else {
                vm.openMaintenanceDialog(service.getRequest(requestId));
            }
        }
    }
})();
