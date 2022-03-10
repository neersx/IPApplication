angular.module('inprotech.mocks')
    .factory('TemplateResolverMock',
        function() {
            'use strict';
            var resolver = {
                resolve: function() {
                    return 'some template';
                }
            };
            spyOn(resolver, 'resolve').and.callThrough();
            return resolver;
        });
