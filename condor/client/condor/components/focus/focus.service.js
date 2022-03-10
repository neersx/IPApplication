angular.module('inprotech.components.focus').factory('focusService', function() {
    'use strict';

    return {
        autofocus: function(element, latency) {
            setTimeout(function() {
                element.find('*[ip-autofocus]:visible').filter(function() {
                    return $(this).attr('ip-autofocus') !== 'false';
                }).trigger('setFocus');
            }, latency || 10);
        }
    };
});
