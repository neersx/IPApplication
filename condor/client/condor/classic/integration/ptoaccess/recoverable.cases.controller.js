angular.module('Inprotech.Integration.PtoAccess')
    .controller('recoverableCasesController', RecoverableCasesController);

function RecoverableCasesController($scope, $uibModalInstance, modalService, options, hotkeys, kendoGridBuilder) {
    'use strict';

    var vm = this;

    vm.initShortcuts = initShortcuts;
    vm.close = close;
    vm.gridOptions = buildGridOptions();

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
                return options.model.recoverableCases;
            }
        });
    }

    function buildColumns() {
        var columns = [{
            title: 'dataDownload.schedule.applicationNumber',
            field: 'applicationNumber',
            width: '33%',
            sortable: true
        }, {
            title: 'dataDownload.schedule.registrationNumber',
            field: 'registrationNumber',
            width: '33%',
            sortable: true
        }, {
            title: 'dataDownload.schedule.publicationNumber',
            field: 'publicationNumber',
            width: '33%',
            sortable: true
        }];

        if (options.model.hasCorrelationId) {
            columns.push({
                title: 'dataDownload.schedule.correlation' + options.model.dataSource,
                field: 'correlationIds'
            });
        }

        return columns;
    }

    function close() {
        $uibModalInstance.dismiss('Cancel');
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (modalService.canOpen('RecoverableCases')) {
                    close();
                }
            }
        });
    }
}