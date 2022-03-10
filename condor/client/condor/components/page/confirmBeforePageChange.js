angular.module('inprotech.components.page').directive('ipConfirmBeforePageChange', function($transitions) {
    'use strict';

    return {
        restrict: 'A',
        scope: {
            shouldShowConfirm: '&ipConfirmBeforePageChange',
            confirmMessage: '@'
        },
        link: function(scope) {
            var unload = $transitions.onStart({}, function() {
                if (scope.shouldShowConfirm() && !window.confirm(scope.confirmMessage)) { // eslint-disable-line no-alert
                    return false;
                }
                unload();
            });

            $(window).bind('beforeunload', beforeunload);

            scope.$on('$destroy', function() {
                $(window).unbind('beforeunload', beforeunload);
            });

            function beforeunload() {
                if (scope.shouldShowConfirm()) {
                    return scope.confirmMessage;
                }
            }
        }
    };
});
