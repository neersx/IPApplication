angular.module('inprotech.mocks')
    .factory('CommonActionsMock',
        function() {
            'use strict';

            var someActionsReturn = [{
                id: 'some',
                click: function() {}
            }];

            var $commonActionsMock = {
                get: function() {
                    return someActionsReturn;
                }
            };

            spyOn($commonActionsMock, 'get').and.callThrough();

            return $commonActionsMock;
        });
