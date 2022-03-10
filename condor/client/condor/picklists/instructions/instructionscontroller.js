(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('instructionsController', function($http, states, selectedInstructionType) {
            var iCtrl = this;

            iCtrl.init = function(maintenanceState, entry) {
                if (maintenanceState === states.adding) {
                    entry.typeId = selectedInstructionType.get();
                }
            };

            $http.get('api/picklists/instructions/instructionTypes')
                .then(function(response) {
                    iCtrl.instructionTypes = response.data;
                });
        });
})();
