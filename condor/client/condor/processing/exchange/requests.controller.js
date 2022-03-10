angular.module('inprotech.processing.exchange')
    .controller('ExchangeRequestsController', function ($scope, $state, $translate, kendoGridBuilder, exchangeQueueService, notificationService, BulkMenuOperations, localSettings) {
        'use strict';
        var vm = this;
        var bulkMenuOperations = new BulkMenuOperations('exchangeRequestListMenu');
        vm.gridOptions = buildGridOptions();
        vm.menu = buildBulkMenu();

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'exchangeRequestList',
                selectable: 'row',
                pageable: {
                    pageSize: localSettings.Keys.exchangeIntegration.exchangeIntegrationQueue.pageNumber.getLocal,
                    pageSizes: [50, 100, 200]
                },
                onPageSizeChanged: function (pageSize) {
                    localSettings.Keys.exchangeIntegration.exchangeIntegrationQueue.pageNumber.setLocal(pageSize);
                },
                autoBind: true,
                read: function (queryParams) {
                    return exchangeQueueService.get(queryParams).then(function (data) {
                        return data;
                    });
                },
                onDataCreated: function () {
                    bulkMenuOperations.selectionChange(vm.gridOptions.data());
                },
                columns: [{
                    headerTemplate: '<div data-bulk-actions-menu data-context="exchangeRequestListMenu" data-actions="vm.menu.items" data-on-clear="vm.menu.clearAll()" data-on-select-all="vm.menu.selectAll(val)" data-items="vm.gridOptions.data()"></div>',
                    template: '<ip-checkbox ng-model="dataItem.selected" ng-change="vm.menu.selectionChange(dataItem)" ng-disabled={{::(dataItem.statusId===1)}}></ip-checkbox>',
                    width: '35px',
                    fixed: true
                }, {
                    title: 'exchangeIntegration.queue.columns.requestDate',
                    field: 'requestDate',
                    template: '<span><ip-date-time model="::dataItem.requestDate"></ip-date-time></span>',
                    width: '12%'
                }, {
                    title: 'exchangeIntegration.queue.columns.typeOfRequest',
                    field: 'typeOfRequest',
                    width: '8%',
                    oneTimeBinding: true
                }, {
                    title: 'exchangeIntegration.queue.columns.staff',
                    field: 'staff',
                    width: '10%',
                    oneTimeBinding: true
                }, {
                    title: 'exchangeIntegration.queue.columns.reference',
                    field: 'reference',
                    width: '10%',
                    oneTimeBinding: true
                }, {
                    title: 'exchangeIntegration.queue.columns.eventDescription',
                    field: 'eventDescription',
                    oneTimeBinding: true,
                    template: function (dataItem) {
                        if (dataItem.requestTypeId === 4 && dataItem.eventDescription) {
                            return dataItem.eventDescription
                        }
                        if (dataItem.eventId) {
                            return dataItem.eventDescription + ' {' + dataItem.eventId + '}';
                        } else {
                            return '';
                        }
                    }
                }, {
                    title: 'exchangeIntegration.queue.columns.mailbox',
                    field: 'mailbox',
                    width: '10%',
                    oneTimeBinding: true
                }, {
                    title: 'exchangeIntegration.queue.columns.recipientEmail',
                    field: 'recipientEmail',
                    width: '10%',
                    oneTimeBinding: true
                }, {
                    title: 'exchangeIntegration.queue.columns.status',
                    field: 'status',
                    width: '10%',
                    oneTimeBinding: true,
                    template: function (dataItem) {
                        if (dataItem.statusId === 3) {
                            return '<span class="text-blue">{{dataItem.status}} <i class="cpa-icon cpa-icon-exclamation-circle" aria-hidden="true" title="Obsolete"></i><span class="sr-only">Obsolete</span></span>';
                        } else
                            if (dataItem.statusId === 2) {
                                return '<span class="text-red">{{dataItem.status}} <i class="cpa-icon cpa-icon-exclamation-circle" aria-hidden="true" title="Error"></i><span class="sr-only">Error</span></span>';
                            } else if (dataItem.statusId === 1) {
                                return '<span class="text-navy">{{ dataItem.status}} <i class="cpa-icon cpa-icon-clock-o" aria-hidden="true" title="Processing"></i><span class="sr-only">Processing</span></span>';
                            } else {
                                return dataItem.status;
                            }
                    }
                }, {
                    title: 'exchangeIntegration.queue.columns.failedMessage',
                    field: 'failedMessage',
                    oneTimeBinding: true
                }]
            });
        }

        function anySelected() {
            return bulkMenuOperations.anySelected(vm.gridOptions.data());
        }

        function buildBulkMenu() {
            return {
                context: 'exchangeRequestListMenu',
                items: [{
                    id: 'resetRequest',
                    text: 'exchangeIntegration.bulkMenu.reset',
                    enabled: anySelected,
                    icon: 'eraser',
                    click: resetExchangeRequest
                }, {
                    id: 'delete',
                    enabled: anySelected,
                    click: deleteExchangeRequest
                }, {
                    id: 'selectObsolete',
                    text: 'exchangeIntegration.bulkMenu.selectObsolete',
                    icon: 'check',
                    click: selectObsolete
                }],
                clearAll: function () {
                    bulkMenuOperations.clearAll(vm.gridOptions.data());
                },
                selectAll: function (val) {
                    bulkMenuOperations.selectAll(_.filter(vm.gridOptions.data(), function (item) {
                        return item.statusId != 1
                    }), val)
                },
                selectionChange: function () {
                    bulkMenuOperations.selectionChange(vm.gridOptions.data());
                }
            };
        }

        function resetExchangeRequest() {
            var ids = _.pluck(_.where(vm.gridOptions.data(), {
                selected: true,
                statusId: 2
            }), 'id');

            exchangeQueueService.reset(ids).then(function (response) {
                if (response.data.result.status === 'success') {
                    if (response.data.result.updated > 0) {
                        notificationService.success();
                        $state.reload();
                    } else {
                        notificationService.alert({
                            message: $translate.instant('exchangeIntegration.bulkMenu.reset-none')
                        });
                    }
                }
            });
        }

        function deleteExchangeRequest() {
            notificationService.confirmDelete({
                message: 'modal.confirmDelete.message'
            }).then(function () {
                var ids = _.pluck(_.where(vm.gridOptions.data(), {
                    selected: true
                }), 'id');
                exchangeQueueService.delete(ids).then(function (response) {
                    if (response.data.result.status === 'success') {
                        notificationService.success();
                        $state.reload();
                    }
                })
            });
        }

        function selectObsolete() {
            bulkMenuOperations.selectAll(_.filter(vm.gridOptions.data(), function (item) {
                return item.statusId === 3
            }), true)
        }
    });