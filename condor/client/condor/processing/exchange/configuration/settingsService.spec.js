describe('inprotech.processing.exchange.exchangeSettingsService', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.processing.exchange');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });

        inject(function(exchangeSettingsService) {
            service = exchangeSettingsService;
        });
    });

    it('save should pass correct parameters', function() {
        service.save('abc');
        expect(httpMock.post).toHaveBeenCalledWith('api/exchange/configuration/save', 'abc');
    });
    it('get should pass correct parameters', function() {
        service.get();
        expect(httpMock.get).toHaveBeenCalledWith('api/exchange/configuration/view');
    });
});
