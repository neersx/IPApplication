angular.module('Inprotech.BulkCaseImport')
    .controller('batchSummaryController', [
        '$scope', 'kendoGridBuilder', 'bulkCaseImportService', 'url', 'localSettings', 'batch',
        function ($scope, kendoGridBuilder, bulkCaseImportService, url, localSettings, batch) {
            'use strict';
            var vm = this;

            vm.$onInit = onInit;

            function onInit() {
                vm.viewData = { batchId: batch.id, batchIdentifier: batch.name, transReturnCode: batch.transReturnCode };

                vm.gridOptions = buildOptions();
            }

            function buildOptions() {
                return kendoGridBuilder.buildOptions($scope, {
                    id: 'bulkImportSummary',
                    autoBind: true,
                    navigatable: true,
                    sortable: false,
                    scrollable: true,
                    pageable: {
                        pageSize: localSettings.Keys.caseImport.batchSummary.pageNumber.getLocal
                    },
                    onPageSizeChanged: function (pageSize) {
                        localSettings.Keys.caseImport.batchSummary.pageNumber.setLocal(pageSize);
                    },
                    selectable: 'row',
                    read: function (queryParams) {
                        return bulkCaseImportService.getBatchSummary(vm.viewData.batchId, vm.viewData.transReturnCode, queryParams);
                    },
                    readFilterMetadata: function (column) {
                        return bulkCaseImportService.getBatchSummaryColumnFilterData(vm.viewData.batchId, vm.viewData.transReturnCode, column.field);
                    },
                    filterOptions: {
                        sendExplicitValues: true
                    },
                    autoGenerateRowTemplate: true,
                    columns: [{
                        title: 'bulkCaseImport.bsLblTransId',
                        field: 'id',
                        width: "78px"
                    }, {
                        title: 'bulkCaseImport.bsLblTransStatus',
                        field: 'status',
                        width: "100px",
                        filterable: true
                    }, {
                        title: 'bulkCaseImport.bsLblResult',
                        field: 'result',
                        width: "70px",
                        fixed: true
                    }, {
                        title: 'bulkCaseImport.bsLblCaseRef',
                        field: 'caseReference',
                        width: "82px",
                        template: '<ip-ie-only-url ng-if="::dataItem.caseReference" data-url="vm.gotoInprotech(dataItem.caseReference)" data-text="dataItem.caseReference"></ip-ie-only-url>',
                        fixed: true
                    }, {
                        title: 'bulkCaseImport.bsLblIssues',
                        field: 'issues',
                        width: "190px",
                        fixed: true,
                        template: '<ul ng-if="dataItem.issues!= null && dataItem.issues.length>0" style="margin-bottom: 0px"><li data-ng-repeat="i in ::dataItem.issues track by $index">{{i}}</li></ul>'
                    }, {
                        title: 'bulkCaseImport.bsLblPropertyType',
                        field: 'propertyType',
                        width: "80px",
                        fixed: true
                    }, {
                        title: 'bulkCaseImport.bsLblCountry',
                        field: 'country',
                        width: "70px",
                        fixed: true
                    }, {
                        title: 'bulkCaseImport.bsLblOfficialNumber',
                        field: 'officialNumber',
                        width: "70px",
                        fixed: true
                    }, {
                        title: 'bulkCaseImport.bsLblCaseTitle',
                        field: 'caseTitle',
                        width: "180px",
                        fixed: true
                    }]
                });

            }

            vm.gotoInprotech = function (caseRef) {
                return url.inprotech('default.aspx?caseref=' + encodeURIComponent(caseRef));
            };
        }
    ]);