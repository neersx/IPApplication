// Globally available resources for all applications.
angular.module('Inprotech.Localisation')
    .factory('globalResources', function() {
        'use strict';
        return {
            //Begin keyboard binding
            keyboardBindingNextItem: 'Next {0}',
            keyboardBindingPreviousItem: 'Previous {0}',
            keyboardBindingDefaultItemLiteral: 'item',
            keyboardBindingShowMenu: '\'?\' to show keyboard shortcuts',
            //End keyboard binding
            _: null
        };
    });