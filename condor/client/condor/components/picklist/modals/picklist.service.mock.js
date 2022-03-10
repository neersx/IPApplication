angular.module('inprotech.mocks')
    .factory('picklistServiceMock',
        function() {
            'use strict';
            var service = {
                openModal: jasmine.createSpy('openModal-spy', function() {
                    return {
                        then: function(cb) {
                            cb(service.openModal.returnValue);
                        }
                    };
                }).and.callThrough()
            };

            return service;
        });