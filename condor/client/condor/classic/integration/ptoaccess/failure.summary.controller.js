angular.module('Inprotech.Integration.PtoAccess')
    .controller('failureSummaryController', FailureSummaryController);

function FailureSummaryController(viewInitialiser) {
    'use strict';

    var vm = this;

    vm.$onInit = onInit;

    function onInit() {
        vm.topicOptions = {
            topics: [{
                key: 'overviewGroup',
                title: 'dataDownload.failureSummary.overview.title',
                subTitle: 'dataDownload.failureSummary.overview.subtitle',
                topics: _.map(viewInitialiser.viewData.failureSummary, function (s) {
                    var subtitle = s.failedCount > 0 ? undefined : "dataDownload.failureSummary.noErrorForDataSource";
                    return {
                        key: s.dataSource,
                        title: 'dataDownload.dataSource.' + s.dataSource,
                        subTitle: subtitle,
                        template: '<ip-failure-summary-source-topic data-topic="$topic">',
                        params: {
                            viewData: s
                        }
                    };
                })
            }],
            actions: []
        };

        if (viewInitialiser.viewData.allowDiagnostics) {
            vm.topicOptions.topics.push({
                key: 'diagnostics',
                title: 'dataDownload.failureSummary.diagnostics.title',
                subTitle: 'dataDownload.failureSummary.diagnostics.subtitle',
                template: '<ip-failure-summary-diagnostics-topic data-topic="$topic" />'
            });
        }
    }
}