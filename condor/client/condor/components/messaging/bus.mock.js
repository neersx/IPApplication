angular.module('inprotech.mocks')
    .factory('BusMock',
        function() {
            'use strict';

            var channel = {
                broadcast: function() {},
                subscribe: function() {},
                unsubscribe: function() {}
            };

            var $bus = {
                channel: function() {},
                singleSubscribe: angular.noop
            };

            spyOn($bus, 'channel').and.returnValue(channel);
            spyOn($bus, 'singleSubscribe');

            spyOn(channel, 'broadcast').and.callThrough();
            spyOn(channel, 'subscribe').and.callThrough();

            return $bus;
        });
