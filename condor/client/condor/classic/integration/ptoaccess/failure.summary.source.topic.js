angular.module('Inprotech.Integration.PtoAccess')
    .component('ipFailureSummarySourceTopic', {
        templateUrl: 'condor/classic/integration/ptoaccess/failure-summary-source.html',
        bindings: {
            topic: '<'
        },
        controllerAs: 'vm',
        controller: function ($scope, $state, $http, notificationService, url, modalService, kendoGridBuilder) {
            'use strict';

            var vm = this;
            vm.$onInit = onInit;

            function onInit() {
                _.extend(vm, vm.topic.params.viewData);

                vm.recover = recover;
                vm.showRecoverableCases = showRecoverableCases;
                vm.showRecoverableCasesHint = showRecoverableCasesHint;

                vm.showRecoverableDocumentsHint = showRecoverableDocumentsHint;
                vm.showRecoverableDocuments = showRecoverableDocuments;
                vm.hasCorrelationId = hasCorrelationId;
                vm.details = details;
                vm.gridOptions = vm.failedCount > 0 ? buildGridOptions() : null;
            }

            function buildGridOptions() {
                return kendoGridBuilder.buildOptions($scope, {
                    id: 'searchResults',
                    sortable: true,
                    scrollable: false,
                    reorderable: false,
                    navigatable: true,
                    serverFiltering: false,
                    autoBind: true,
                    columns: buildColumns(),
                    read: function search() {
                        return vm.schedules;
                    }
                });
            }

            function buildColumns() {
                var columns = [{
                    title: 'dataDownload.schedules.description',
                    width: '40%',
                    template: '<a data-ng-click="vm.details(dataItem.scheduleId)">{{dataItem.name}}</a>'
                }, {
                    title: 'dataDownload.failureSummary.failedCases',
                    template: '<span data-ng-if="dataItem.failedCasesCount==0">0</span><a data-ng-if="dataItem.failedCasesCount>0" data-ng-click="vm.showRecoverableCases(dataItem.scheduleId, dataItem.aggregateFailures)">{{dataItem.failedCasesCount}}</a>'
                }, {
                    title: 'dataDownload.failureSummary.failedDocuments',
                    template: '<span data-ng-if="dataItem.failedDocumentsCount===0">0</span><a data-ng-if="dataItem.failedDocumentsCount>0" data-ng-click="vm.showRecoverableDocuments(dataItem.scheduleId, dataItem.aggregateFailures)">{{dataItem.failedDocumentsCount}}</a>'
                }];

                if (hasCorrelationId()) {
                    columns.push({
                        title: 'dataDownload.schedule.correlation' + vm.dataSource,
                        field: 'correlationIds'
                    });
                }

                return columns;
            }
            function showRecoverableDocumentsHint() {
                return vm.failedDocumentCount > 0;
            }

            function showRecoverableDocuments(scheduleId, aggregateFailures) {
                var documents = [];

                if (scheduleId) {
                    documents = (aggregateFailures) ? vm.documents : _.where(vm.documents, {
                        scheduleId: scheduleId
                    });
                } else {
                    documents = vm.documents;
                }

                modalService.openModal({
                    id: 'RecoverableDocuments',
                    controllerAs: 'vm',
                    model: {
                        recoverableDocuments: documents,
                        hasCorrelationId: vm.hasCorrelationId(),
                        dataSource: vm.dataSource
                    }
                });
            }

            function showRecoverableCasesHint() {
                return vm.failedCount > 0;
            }

            function showRecoverableCases(scheduleId, aggregateFailures) {
                var cases = [];

                if (scheduleId) {
                    cases = (aggregateFailures) ? _.map(_.groupBy(vm.cases, function (c) {
                        return c.applicationNumber + '*' + c.publicationNumber + '*' + c.registrationNumber;
                    }), function (g) {
                        return g[0];
                    }) : _.where(vm.cases, {
                        scheduleId: scheduleId
                    });
                } else {
                    var casesToConsider = vm.cases;

                    _.each(casesToConsider, function (c) {
                        var selectedCase = _.findWhere(cases, {
                            artifactId: c.artifactId,
                            artifactType: c.artifactType
                        });

                        if (selectedCase) {
                            selectedCase.correlationIds = selectedCase.correlationIds + ', ' + c.correlationIds;
                        } else {
                            cases.push(angular.extend({}, c));
                        }
                    });
                }

                modalService.openModal({
                    id: 'RecoverableCases',
                    controllerAs: 'vm',
                    model: {
                        recoverableCases: cases,
                        hasCorrelationId: vm.hasCorrelationId(),
                        dataSource: vm.dataSource
                    }
                });
            }

            function recover() {
                $http.post(url.api('ptoaccess/failuresummary/retryall/' + vm.dataSource))
                    .then(function () {
                        notificationService.success('dataDownload.schedule.recoveryIssued');
                        vm.recoverPossible = false;
                    });
            }

            function hasCorrelationId() {
                return vm.failedCount > 0 && _.any(vm.cases, function (item) {
                    return item.correlationIds;
                });
            }

            function details(id) {
                $state.go('classicPtoAccess.SchedulesDetail', { id: id });
            }
        }
    });