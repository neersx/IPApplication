angular.module('inprotech.mocks')
    .factory('ModalInstanceMock',
        function(promiseMock) {
            'use strict';

            var $uibModalInstanceMock = {
                close: promiseMock.createSpy(null, true),
                dismiss: promiseMock.createSpy(null, true),
                result: promiseMock.createSpy('result', true),
                opened: promiseMock.createSpy(null, true),
                rendered: promiseMock.createSpy(null, true),
                closed: promiseMock.createSpy(null, true)
            };

            return $uibModalInstanceMock;
        });
