angular.module('inprotech.mocks')
    .factory('PersistablesMock',
        function() {
            'use strict';

            function makeRestmoddy(entry) {
                return _.extend(entry, {
                    $then: function(fn) {
                        fn({});
                    }
                });
            }

            var mock = {
                prepare: function(api, state, original) {
                    return {
                        state: state,
                        template: 'some template',
                        entry: makeRestmoddy(!original ? {} : angular.copy(original))
                    };
                }
            };

            spyOn(mock, 'prepare').and.callThrough();

            return mock;
        });
