angular.module('inprotech.processing.policing')
    .controller('PolicingRequestAffectedCasesController', function($uibModalInstance, totalAffectedCases) {
        'use strict';
        var vm = this;

        vm.ok = ok;
        vm.totalAffectedCases = totalAffectedCases;


        function ok() {
            $uibModalInstance.close('Ok');
        }
    });