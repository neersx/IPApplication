(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('nametypegroupApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/nameTypeGroup'), {});
            }
        ]);
})();
