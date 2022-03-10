angular.module('Inprotech.Integration.PtoAccess')
    .controller('errorDetailsController', ErrorDetailsController);

function ErrorDetailsController($uibModalInstance, modalService, options, hotkeys) {
    'use strict';

    var vm = this;
    vm.errorDetails = options.errorDetails;
    vm.initShortcuts = initShortcuts;
    vm.close = close;

    function close() {
        $uibModalInstance.dismiss('Cancel');
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (modalService.canOpen('ErrorDetails')) {
                    close();
                }
            }
        });
    }
}