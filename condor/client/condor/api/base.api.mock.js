angular.module('inprotech.mocks')
    .factory('BaseApiMock',
        function() {
            'use strict';

            var someApiMockSearchReturn = {
                $then: function(fn) {
                    fn([]);
                }
            };

            var SomeApiMock = {
                $search: function() {
                    return someApiMockSearchReturn;
                },
                $find: function() {
                    return {
                        $then: function(fn) {
                            fn({});
                        }
                    };
                }
            };

            spyOn(SomeApiMock, '$search').and.callThrough();
            spyOn(someApiMockSearchReturn, '$then').and.callThrough();
            spyOn(SomeApiMock, '$find').and.callThrough();

            return SomeApiMock;
        });
