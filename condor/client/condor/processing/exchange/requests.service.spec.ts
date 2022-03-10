'use strict';
namespace inprotech.processing.exchange {
    declare var test: any;
    describe('Exchange requests service', function() {
        let service: any, http;

        beforeEach(function() {
            angular.mock.module(function() {
                http = test.mock('$http', 'httpMock');
            });
            angular.mock.module('inprotech.processing.exchange');
        });

        beforeEach(function() {
            inject(function(exchangeQueueService) {
                service = exchangeQueueService;
            });
        });

        it('returns exchange requests from the server', function() {
            service.get({
                skip: 0
            });
            expect(http.post).toHaveBeenCalledWith('api/exchange/requests/view', JSON.stringify({ skip: 0 }));
        });
        it('calls the correct api for reset', function () {
            service.reset([100, 101, -100, -101]);
            expect(http.post).toHaveBeenCalledWith('api/exchange/requests/reset', [100, 101, -100, -101]);
        });
        it('calls the correct api for delete', function () {
            service.delete([100, 101, -100, -101]);
            expect(http.post).toHaveBeenCalledWith('api/exchange/requests/delete', [100, 101, -100, -101]);
        });
    });
}