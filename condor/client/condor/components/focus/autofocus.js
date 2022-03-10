angular.module('inprotech.components.focus').directive('ipAutofocus', function($timeout) {
    'use strict';

    return {
        restrict: 'A',
        priority: 100,
        link: function(scope, element, attrs) {
            var tagName = element.prop('tagName').toLowerCase();

            if (_.contains(['input', 'select', 'textarea'], tagName)) {
                var timeout = 0;
                if (element.closest('.modal-body').length > 0) {
                    // IE needs to wait for modal animations to complete
                    timeout = 800;
                }

                element.bind('setFocus', function(e) {
                    $timeout(function() {
                        e.target.focus();
                    }, timeout);
                });

                element.on('$destroy', function() {
                    element.unbind('setFocus');
                });
            }

            if (attrs.ipAutofocus === '' || attrs.ipAutofocus === 'true') {
                // trigger event immediately (otherwise controller must trigger manually)
                element.trigger('setFocus');
            }
        }
    };
});
