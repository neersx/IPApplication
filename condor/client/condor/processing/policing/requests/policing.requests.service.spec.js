describe('inprotech.processing.policing.requests.policingRequestService', function() {
    'use strict';
    var service, httpMock, prevRequestCanceller;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing']);

            httpMock = $injector.get('httpMock');
            httpMock.get.returnValue = {};

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
    });

    beforeEach(inject(function(policingRequestService) {
        service = policingRequestService;
    }));

    _.debounce = function(func) {
        return function() {
            func.apply(this, arguments);
        };
    };

    describe('policing requests', function() {
        it('should get view data', function() {
            service.get();
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/requests/view');
        });

        it('should get all requests', function() {
            var queryParams = {
                sortBy: "text",
                sortDir: 'asc'
            };
            service.getRequests(queryParams);

            expect(httpMock.get).toHaveBeenCalledWith('api/policing/requests', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should get single request', function() {
            service.getRequest(1);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/requests/1');
        });

        it('should create new request', function() {
            var request = {
                title: '',
                notes: '',
                startDate: null,
                endDate: null,
                dateLetters: null,
                dueDateOnly: false,
                forDays: null,
                options: {
                    reminders: true,
                    emailReminders: true,
                    documents: true,
                    update: false,
                    adhocReminders: false,
                    recalculateCriteria: false,
                    recalculateDueDates: false,
                    recalculateReminderDates: false,
                    recalculateEventDates: false
                }
            };

            service.save(request);
            expect(httpMock.post).toHaveBeenCalledWith('api/policing/requests', request);
        });

        it('should update existing request', function() {
            var request = {
                requestId: 1,
                title: 'test',
                notes: 'note',
                startDate: null,
                forDays: null,
                options: {
                    reminders: true,
                    emailReminders: false,
                    recalculateEventDates: false
                }
            };
            service.save(request);
            expect(httpMock.put).toHaveBeenCalledWith('api/policing/requests/1', request);
        });

        it('should delete selected requests', function() {
            var requestIds = [1, 2, 3, 4];

            service.delete(requestIds);
            expect(httpMock.post).toHaveBeenCalledWith('api/policing/requests/delete', requestIds);
        });

        it('should call to validate characteristics and call callback method', function() {
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

            service.validateCharacteristics(input, callbackObj.callbackMethod);

            expect(httpMock.get).toHaveBeenCalledWith('api/policing/requests/validateCharacteristics', {
                params: {
                    characteristics: JSON.stringify(input)
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

            service.validateCharacteristics(input, callbackObj.callbackMethod);
            service.validateCharacteristics(input, callbackObj.callbackMethod);

            expect(prevRequestCanceller.cancel).toHaveBeenCalled();
            expect(callbackObj.callbackMethod).toHaveBeenCalled();
        });
    });
});