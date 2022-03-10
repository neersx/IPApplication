(function() {
    'use strict';
    angular.module('inprotech.components.messaging')
        .service('bus', function() {
            return {
                channel: function(channel) {
                    /*eslint-disable */
                    return radio(channel);
                    /*eslint-enable */
                },
                singleSubscribe: function(channel, callback) {
                    /*eslint-disable */
                    radio().channels[channel] = [];
                    radio(channel).subscribe(callback);
                    /*eslint-enable*/
                }
            };
        });
})();
