(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('dataItemsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/dataItems'), {
                    confirmDeleteMessage: 'dataItem.confirmDelete'
                });
            }
        ]);
})();