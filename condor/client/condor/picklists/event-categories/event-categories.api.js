(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('eventCategoriesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/eventCategories'), {});
            }
        ]);
})();
