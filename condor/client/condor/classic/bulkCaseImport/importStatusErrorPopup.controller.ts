module Inprotech.BulkCaseImport {
    'use strict';
    export class ImportStatusErrorPopupController {
        static $inject: string[] = ['options', '$uibModalInstance'];
        public vm: ImportStatusErrorPopupController;
        constructor(public options, private $uibModalInstance) {
        }

        ok = () => {
            this.$uibModalInstance.dismiss('');
        }
    }
    angular.module('Inprotech.BulkCaseImport')
        .controller('ImportStatusErrorPopupController', ImportStatusErrorPopupController);
}