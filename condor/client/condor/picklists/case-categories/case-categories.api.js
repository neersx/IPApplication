(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('caseCategoriesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/caseCategories'), {});
            }
        ]);        
})();
