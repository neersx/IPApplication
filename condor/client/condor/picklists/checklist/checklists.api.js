(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('checklistApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/checklist'), {});
            }
        ]);
})();
