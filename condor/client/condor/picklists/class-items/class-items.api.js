(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('classItemsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/classItems'), {
                    rerunSearch: true,
                    confirmDeleteCancel: 'modal.confirmation.cancel',
                    confirmDeleteContinue: 'modal.confirmation.delete'
                });
            }
        ]);
})();