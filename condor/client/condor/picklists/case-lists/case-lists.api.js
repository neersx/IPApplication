(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('caseListsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/caseLists'), {});
            }
        ]);
})();
