module inprotech.names.consolidation {
    'use strict';
    export class NamesConsolidationConfirmationController {
        static $inject: string[] = ['options', '$uibModalInstance'];
        public vm: NamesConsolidationController;
        constructor(public options, private $uibModalInstance) {

        }

        proceed = () => {
            this.$uibModalInstance.close(true);
        }

        cancel = () => {
            this.$uibModalInstance.dismiss('Cancel');
        }

    }
    angular.module('inprotech.names.consolidation')
        .controller('NamesConsolidationConfirmationController', NamesConsolidationConfirmationController);
}