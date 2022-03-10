(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('caseCategoriesController', function(states, selectedCaseType) {
            var iCtrl = this;

            iCtrl.init = function(maintenanceState, entry) {
                if (maintenanceState === states.adding) {
                    entry.caseTypeId = selectedCaseType.get().code;
                    entry.caseTypeDescription = selectedCaseType.get().value;
                }
            };

        });
})();