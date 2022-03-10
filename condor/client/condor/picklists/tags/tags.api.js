(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('tagsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/tags'), {});
            }
        ]);
})();
