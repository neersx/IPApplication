angular.module('Inprotech.Integration.PtoAccess')
    .controller('recoverableDocumentsController', RecoverableDocumentsController);

function RecoverableDocumentsController($scope, $uibModalInstance, modalService, options, hotkeys, kendoGridBuilder) {
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
                return options.model.recoverableDocuments;
            }
        });
    }

    function buildColumns() {
        var columns = [{
            title: 'dataDownload.schedule.applicationNumber',
            field: 'applicationNumber',
            sortable: true
        }, {
            title: 'dataDownload.schedule.registrationNumber',
            field: 'registrationNumber',
            sortable: true
        }, {
            title: 'dataDownload.schedule.publicationNumber',
            field: 'publicationNumber',
            sortable: true
        }, {
            title: 'dataDownload.schedule.documentDescription',
            field: 'documentDescription',
            sortable: true
        }, {
            title: 'dataDownload.schedule.documentCode',
            field: 'documentCode',
            sortable: true
        }, {
            title: 'dataDownload.schedule.mailRoomDate',
            field: 'mailRoomDate',
            sortable: true,
            template: function () {
                return '<ip-date model="dataItem.mailRoomDate"></ip-date>';
            }
        }, {
            title: 'dataDownload.schedule.lastChecked',
            field: 'updatedOn',
            width: '150px',
            sortable: true,
            template: function () {
                return '<ip-date-time model="dataItem.updatedOn"></ip-date-time>';
            }
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
                if (modalService.canOpen('RecoverableDocuments')) {
                    close();
                }
            }
        });
    }
}