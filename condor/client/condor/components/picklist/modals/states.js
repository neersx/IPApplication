(function() {
    'use strict';
    angular.module('inprotech.components.picklist')
        .factory('states', function() {
            return {
                initialising: 'initialising',
                normal: 'normal',
                adding: 'adding',
                duplicating: 'duplicating',
                updating: 'updating',
                deleting: 'deleting',
                viewing: 'viewing'
            };
        });
})();
