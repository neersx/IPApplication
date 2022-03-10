(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('relationshipsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/relationship'), {});
            }
        ]);
})();
