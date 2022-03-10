angular.module('Inprotech.BulkCaseImport')
    .controller('importStatusController', ['$scope', 'http', 'notificationService', 'localSettings', 'bulkCaseImportService', 'BulkMenuOperations', 'url', '$translate', 'kendoGridBuilder', 'messageBroker', 'permissions', 'modalService', 'scheduler',
        function ($scope, http, notificationService, localSettings, bulkCaseImportService, BulkMenuOperations, url, $translate, kendoGridBuilder, messageBroker, permissions, modalService, scheduler) {
            'use strict';

            var hasMenu = permissions.canReverseBatch;
            var vm = this;
            var bulkOperation;

            vm.$onInit = onInit;

            function onInit() {
                vm.status = 'idle';
                vm.gridOptions = buildOptions();
                vm.isServiceBrokerEnabled = true;
                vm.menu = buildMenu();

                bulkOperation = new BulkMenuOperations(vm.menu.context);
            }

            vm.onViewDetails = function (errors) {
                modalService.openModal({
                    id: 'ImportStatusErrorPopup',
                    details: errors
                })
            };

            vm.resubmitBatch = function (batch) {
                vm.resubmittedBatch = batch;
                http.post(url.api('bulkcaseimport/resubmitbatch'), { 'batchId': batch.id })
                    .success(function (response) {
                        onComplete(response, 'Resubmit', 'Resubmitted', vm.resubmittedBatch);
                    });
            };

            function translateOptions(options) {
                angular.forEach(options, function (o) {
                    if (o.description) {
                        o.description = $translate.instant('bulkCaseImport.' + o.description);
                    }
                })
                return options;
            }

            function buildMenu() {
                return {
                    context: 'importStatus',
                    items: [{
                        id: 'reverse',
                        text: 'bulkCaseImport.action.reverseBatch',
                        enabled: function () {
                            var items = bulkOperation.selectedRecords(vm.gridOptions.data());
                            return _.filter(items, function (i) {
                                return i.isReversible && i.statusType !== 'SubmittedForReversal' && i.statusType !== 'Resubmitted';
                            }).length === 1;
                        },
                        click: startReverseBatchWorkflow
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

            function startReverseBatchWorkflow() {
                var selectedItem = bulkOperation.selectedRecord(vm.gridOptions.data());
                notificationService.confirm({
                    message: 'bulkCaseImport.confirmReverseBatch',
                    messageParams: {
                        identifier: selectedItem.batchIdentifier
                    }
                }).then(function () {
                    reverseBatch(selectedItem).then(function (res) {
                        if (res.data.status == 'success') {
                            notificationService.success();
                        } else if (res.data.status == 'error') {
                            notificationService.alert({
                                title: 'modal.unableToComplete',
                                message: 'bulkCaseImport.importStatus.errors.' + res.data.error
                            }, $scope);
                        }
                    });
                });
            }

            function reverseBatch(batch) {
                return http.post(url.api('bulkcaseimport/reversebatch'), { 'batchId': batch.id })
                    .success(function (response) {
                        onComplete(response, 'Reverse', 'SubmittedForReversal', batch);
                    });
            }

            function onComplete(response, mode, status, batch) {
                if (response.result === 'success') {
                    if (batch) {
                        notificationService.success('bulkCaseImport.is' + mode + 'SuccessMessage', {
                            identifier: batch.batchIdentifier
                        });
                        vm.status = 'success';
                        batch.statusType = status;
                        batch.statusMessage = $translate.instant('bulkCaseImport.is' + status);
                        return;
                    }
                }
                if (response.result === 'error') {
                    if (batch) {
                        notificationService.alert({
                            title: $translate.instant('bulkCaseImport.bciError'),
                            errors: response.errorCode ? $translate.instant('bulkCaseImport.errors.' + response.errorCode) : response.errorMessage
                        });
                        vm.status = 'idle';
                        return;
                    }
                }
            }

            function buildGridColumns() {
                var columns = [{
                    title: 'bulkCaseImport.isLblSubmittedDate',
                    field: 'submittedDate',
                    width: "200px",
                    fixed: true,
                    locked: true,
                    template: function () {
                        return '<ip-date-time model="dataItem.submittedDate"></ip-date-time>';
                    }
                }, {
                    title: 'bulkCaseImport.isLblStatus',
                    field: 'displayStatusType',
                    width: "150px",
                    fixed: true,
                    filterable: true,
                    locked: true,
                    template: function () {
                        return '<div style="width:125px;"><span data-ng-if="dataItem.statusMessage">{{ dataItem.statusMessage | translate }}</span>' +

                            '<span data-ng-if="dataItem.statusType === \'Error\'">' +
                            '<a id="error_{{dataItem.id}}" data-ng-if="dataItem.otherErrors" data-ng-click="vm.onViewDetails(dataItem.otherErrors)">{{ \'bulkCaseImport.\' + dataItem.displayStatusType | translate }}</a><span data-ng-if="!dataItem.otherErrors">{{ \'bulkCaseImport.\' + dataItem.displayStatusType | translate }}</span></span>' +

                            '<span data-ng-if="dataItem.statusType === \'InProgress\'">{{\'bulkCaseImport.\' + dataItem.displayStatusType | translate }}</span>' +
                            '<button id="resubmit_{{dataItem.id}}" type="button" class="btn btn-primary btn-xs pull-right" data-ng-if="dataItem.statusType === \'Error\' || dataItem.statusType === \'ResolutionRequired\'" ip-tooltip="{{ \'bulkCaseImport.isLblResubmitBatch\' | translate }}"  data-ng-click="vm.resubmitBatch(dataItem)">' +
                            '<span class="cpa-icon cpa-icon-repeat"></span>' +
                            '</button></span></div>';
                    }
                }, {
                    title: 'bulkCaseImport.isLblBatchIdentifier',
                    field: 'batchIdentifier',
                    width: "200px",
                    wrapText: true,
                    locked: true,
                    fixed: true,
                    template: function () {
                        return '<span style="word-break: break-word;">{{dataItem.batchIdentifier}}</span>';
                    }
                }, {
                    title: 'bulkCaseImport.isLblTotal',
                    field: 'total',
                    fixed: true,
                    width: "100px",
                    template: function () {
                        return '<a id="total_{{dataItem.id}}" ui-sref="classicBulkCaseBatchSummary({batchId: {{dataItem.id}}, batchIdentifier:\'{{dataItem.batchIdentifier}}\' })">{{dataItem.total}}</a>';
                    }
                }, {
                    title: 'bulkCaseImport.isLblCompleted',
                    fixed: true,
                    width: "280px",
                    columns: [{
                        title: 'bulkCaseImport.isLblNewCases',
                        field: 'newCases',
                        fixed: true,
                        width: "110px",
                        template: function () {
                            return '<a href="../{{dataItem.newCasesUrl}}" target="_blank">{{dataItem.newCases}}</a>';
                        }
                    }, {
                        title: 'bulkCaseImport.isLblAmended',
                        field: 'amended',
                        fixed: true,
                        width: "110px",
                        template: function () {
                            return '<a id="amended_{{dataItem.id}}" ui-sref="classicBulkCaseBatchSummaryReturnCode({batchId: {{dataItem.id}}, transReturnCode:\'amendedCases\', batchIdentifier:\'{{dataItem.batchIdentifier}}\' })">{{dataItem.amended}}</a>';
                        }
                    }, {
                        title: 'bulkCaseImport.isLblNoChange',
                        field: 'noChange',
                        fixed: true,
                        width: "130px",
                        template: function () {
                            return '<a id="unchanged_{{dataItem.id}}" ui-sref="classicBulkCaseBatchSummaryReturnCode({batchId: {{dataItem.id}}, transReturnCode:\'noChangeCases\', batchIdentifier:\'{{dataItem.batchIdentifier}}\' })">{{dataItem.noChange}}</a>';
                        }
                    }]
                }, {
                    title: 'bulkCaseImport.isLblRejectedCases',
                    field: 'rejected',
                    fixed: true,
                    width: "130px",
                    template: function () {
                        return '<a id="rejected_{{dataItem.id}}" ui-sref="classicBulkCaseBatchSummaryReturnCode({batchId: {{dataItem.id}}, transReturnCode:\'rejectedCases\', batchIdentifier:\'{{dataItem.batchIdentifier}}\' })">{{dataItem.rejected}}</a>';
                    }
                }, {
                    title: 'bulkCaseImport.isLblInError',
                    fixed: true,
                    width: "320px",
                    columns: [{
                        title: 'bulkCaseImport.isLblNotMapped',
                        field: 'notMapped',
                        fixed: true,
                        width: "130px",
                        template: function () {
                            return '<a id="unmapped_{{dataItem.id}}" href=\'#/bulkcaseimport/issues/mapping/{{dataItem.id}}\'>{{dataItem.notMapped}}</a>';
                        }
                    }, {
                        title: 'bulkCaseImport.isLblNameIssues',
                        field: 'nameIssues',
                        fixed: true,
                        width: "130px",
                        template: function () {
                            return '<a id="nameIssues_{{dataItem.id}}" href=\'#/bulkcaseimport/issues/name/{{dataItem.id}}\'>{{dataItem.nameIssues}}</a>';
                        }
                    }, {
                        title: 'bulkCaseImport.isLblUnresolved',
                        field: 'unresolved',
                        fixed: true,
                        width: "120px",
                        template: function () {
                            return '<a id="incomplete_{{dataItem.id}}" ui-sref="classicBulkCaseBatchSummaryReturnCode({batchId: {{dataItem.id}}, transReturnCode:\'incomplete\', batchIdentifier:\'{{dataItem.batchIdentifier}}\' })">{{dataItem.unresolved}}</a>';
                        }
                    }]
                }, {
                    title: 'bulkCaseImport.isLblSource',
                    field: 'isHomeName',
                    fixed: true,
                    width: "270px",
                    template: function () {
                        return '{{dataItem.source}}<span data-ng-show="dataItem.isHomeName === true">({{ \'bulkCaseImport.isLblIsHomeName\' | translate}})</span>';
                    }
                }
                ];

                if (hasMenu) {
                    columns.unshift({
                        headerTemplate: '<div data-bulk-actions-menu data-context="importStatus" data-actions="vm.menu.items" data-on-select-all="vm.menu.selectAll(val)" data-on-clear="vm.menu.clearAll()" data-initialised="vm.menu.initialised()"></div>',
                        template: function () {
                            return '<ip-checkbox ng-model="dataItem.selected" ng-change="vm.menu.selectionChange(dataItem)">';
                        },
                        width: '34px',
                        fixed: true,
                        locked: true
                    });
                }

                return columns;
            }

            function buildOptions() {
                var options = {
                    id: 'importStatus',
                    autoBind: true,
                    navigatable: true,
                    sortable: false,
                    scrollable: true,
                    selectable: 'row',
                    pageable: {
                        pageSize: localSettings.Keys.caseImport.status.pageNumber.getLocal
                    },
                    onDataCreated: selectionChange,
                    onPageSizeChanged: function (pageSize) {
                        localSettings.Keys.caseImport.status.pageNumber.setLocal(pageSize);
                    },
                    read: function (queryParams) {
                        return bulkCaseImportService.getImportStatus(queryParams);
                    },
                    readFilterMetadata: function (column) {
                        return bulkCaseImportService.getImportStatusColumnFilterData(column.field)
                            .then(function (data) {
                                return translateOptions(data);
                            });
                    },
                    filterOptions: {
                        keepFiltersAfterRead: false,
                        sendExplicitValues: true
                    },
                    columns: buildGridColumns()
                };

                return kendoGridBuilder.buildOptions($scope, options);
            }

            var receiveStatusUpdate = function () {
                var topicServiceBroker = 'processing.backgroundServices.status';

                messageBroker.disconnect();
                messageBroker.subscribe(topicServiceBroker, function (data) {
                    scheduler.runOutsideZone(function () {
                        $scope.$apply(function () {
                            vm.isServiceBrokerEnabled = data;
                        });
                    });
                });

                messageBroker.connect();
            };

            receiveStatusUpdate();

            $scope.$on('$destroy', function () {
                messageBroker.disconnect();
            });
        }
    ]);