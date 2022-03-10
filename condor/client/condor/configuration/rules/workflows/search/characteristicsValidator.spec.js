describe('inprotech.configuration.rules.workflows.characteristicsValidator', function() {
    'use strict';

    var validator, httpMock, prevRequestCanceller;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);

            prevRequestCanceller = {
                cancel: angular.noop,
                promise: ''
            };

            spyOn(prevRequestCanceller, 'cancel').and.callThrough();

            $provide.value('utils', {
                cancellable: function() {
                    return prevRequestCanceller;
                }
            });
        });

        inject(function(characteristicsValidator) {
            validator = characteristicsValidator;
        });
    });

    _.debounce = function(func) {
        return function() {
            func.apply(this, arguments);
        };
    };

    it('should call api with correct parameters with callback', function() {
        var input = {
            a: 1
        };

        var callbackObj = {
            callbackMethod: function(data) {
                return data;
            }
        };
        spyOn(callbackObj, 'callbackMethod');

        var httpGetResponse = {};
        httpMock.get.returnValue = httpGetResponse;

        validator.validate(input, callbackObj.callbackMethod);

        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/characteristics/validateCharacteristics', {
            params: {
                criteria: JSON.stringify(input),
                purposeCode: 'E'
            },
            timeout: prevRequestCanceller.promise
        });
        expect(callbackObj.callbackMethod).toHaveBeenCalledWith(httpGetResponse);
    });

    it('should cancel previous pending request with callback', function() {
        var input = {
            a: 1
        };
        var callbackObj = {
            callbackMethod: function(data) {
                return data;
            }
        };
        spyOn(callbackObj, 'callbackMethod');

        validator.validate(input, callbackObj.callbackMethod);
        validator.validate(input, callbackObj.callbackMethod);

        expect(prevRequestCanceller.cancel).toHaveBeenCalled();
        expect(callbackObj.callbackMethod).toHaveBeenCalled();
    });
});
