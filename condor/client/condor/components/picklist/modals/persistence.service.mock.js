angular.module('inprotech.mocks')
    .factory('PersistenceServiceMock',
        function() {
            'use strict';
            var service = {
                saveResult: {
                    result: 'success'
                },
                save: function(scope, entry, hasInlineGrid, refresh) {
                    refresh(service.saveResult);
                },
                delete: function(entry, success) {
                    success();
                },
                abandon: function(entry, state, force, returnToNormal) {
                    returnToNormal();
                }

            };
            return service;
        });