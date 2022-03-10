angular.module('inprotech.mocks')
    .factory('TranslationFilterMock',
        function() {
            'use strict';

            var translate = function(value) {
                return value;
            };

            translate = jasmine.createSpy('translateSpy', translate).and.callThrough();

            return translate;
        });
