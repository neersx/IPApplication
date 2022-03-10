angular.module('Inprotech.Integration.PtoAccess')
    .component('ipFailureSummaryDiagnosticsTopic', {
        template: '<button id="failureSummary" class="btn btn-prominent clear"><span translate="dataDownload.failureSummary.diagnostics.collectDownload" data-ng-click="vm.download();"></span></button>',
        bindings: {
            topic: '<'
        },
        controllerAs: 'vm',
        controller: function (url) {
            'use strict';

            var vm = this;

            vm.$onInit = onInit;

            function onInit() {
                vm.download = download;
            }

            function download() {
                window.location = url.api('ptoaccess/diagnostics/download-logs');
            }
        }
    });