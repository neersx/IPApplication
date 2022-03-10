describe('Inprotech.BulkCaseImport.resubmitController', function() {
    'use strict';

    var _scope, _controller, _http, notificationService;

    beforeEach(function() {
        module('Inprotech.BulkCaseImport')
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.components.notification', 'inprotech.mocks.core']);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);
        });
    });

    beforeEach(inject(function($rootScope, $controller, $httpBackend) {

        _scope = _.extend($rootScope.$new(), {
            viewData: {
                batchId: 1,
                batchIdentifier: '12345'
            }
        });
        _http = $httpBackend;

        _controller = function() {
            return $controller('resubmitController', {
                '$scope': _scope
            });
        };
    }));

    describe('resubmitting a batch', function() {
        it('sends a http request', function() {
            _controller();

            _http.expectPOST('api/bulkcaseimport/resubmitbatch', '{"batchId":1}')
                .respond(function() {
                    return [200, {
                        result: {
                            result: 'success'
                        }
                    }];
                });

            _scope.resubmitBatch({
                id: 1
            });
            _http.flush();

            expect(notificationService.success).toHaveBeenCalled();
            expect(_scope.resubmitStatus).toBe('success');
        });

        it('relays handled errors from server', function() {
            _controller();

            _http.whenPOST('api/bulkcaseimport/resubmitbatch').respond(function() {
                return [200, {
                    result: {
                        result: 'error',
                        errorMessage: 'errorMessage'
                    }
                }];
            });

            _scope.resubmitBatch({});
            _http.flush();

            expect(notificationService.alert).toHaveBeenCalledWith(jasmine.objectContaining({
                message: 'errorMessage'
            }));
            expect(_scope.resubmitStatus).toBe('idle');
        });
    });
});