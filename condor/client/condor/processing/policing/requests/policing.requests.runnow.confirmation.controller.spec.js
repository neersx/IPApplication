describe('inprotech.processing.policing.PolicingRequestRunNowConfirmationController', function() {
    'use strict';
    var scope, controller, modelInstance, request, affectedCasesService, promiseMock, canCalculateAffectedCases;
    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing', 'inprotech.mocks.core']);

            modelInstance = $injector.get('ModalInstanceMock');
            $provide.value('$uibModalInstance', modelInstance);

            affectedCasesService = $injector.get('policingRequestAffectedCasesServiceMock');
            $provide.value('policingRequestAffectedCasesService', affectedCasesService);

            $provide.value('request', request);

            promiseMock = $injector.get('promiseMock');
        });
    });

    beforeEach(inject(function($controller, $rootScope) {
        affectedCasesService.getAffectedCases = promiseMock.createSpy({
            data: {
                isSupported: true,
                noOfCases: 1
            }
        });
        canCalculateAffectedCases = true;
        scope = $rootScope.$new();
        spyOn(scope, '$apply').and.callFake(function(cb) {
            return cb();
        });
        controller = function(request) {
            return $controller('PolicingRequestRunNowConfirmationController', {
                $scope: scope,
                request: request,
                canCalculateAffectedCases: canCalculateAffectedCases
            });

        };
    }));

    it('should initialize', function() {
        request = {
            startDate: new Date('20160825'),
            endDate: new Date('20160826')
        };
        controller(request);
        expect(scope.runMode.type).toBe(1);
    });

    describe('Should set dates', function() {
        beforeEach(function() {

        });

        it('should not change dates if start and end dates are provided', function() {
            request = {
                startDate: new Date('20160825'),
                endDate: new Date('20160826')
            };
            controller(request);
            expect(scope.request.startDate).toBe(request.startDate);
            expect(scope.request.endDate).toBe(request.endDate);
        });

        it('should not change dates if days are not provided', function() {
            request = {
                startDate: null,
                endDate: null,
                forDays: null
            };
            controller(request);
            expect(scope.request.startDate).toBe(request.startDate);
            expect(scope.request.endDate).toBe(request.endDate);
            expect(scope.request.forDays).toBe(request.forDays);
        });

        it('should not change dates if start date is provided', function() {
            request = {
                startDate: new Date('20160825'),
                endDate: null,
                forDays: 5
            };
            controller(request);
            expect(scope.request.startDate).toBe(request.startDate);
            expect(scope.request.endDate).toBe(request.endDate);
            expect(scope.request.forDays).toBe(request.forDays);
        });

        it('should not change dates if end date is provided', function() {
            request = {
                startDate: null,
                endDate: new Date('20160825'),
                forDays: 5
            };
            controller(request);
            expect(scope.request.startDate).toBe(request.startDate);
            expect(scope.request.endDate).toBe(request.endDate);
            expect(scope.request.forDays).toBe(request.forDays);
        });

        it('should set date for positive days', function() {
            request = {
                startDate: null,
                endDate: null,
                forDays: 5
            };
            controller(request);
            var today = new Date();
            var future = new Date();
            future.setDate(today.getDate() + (request.forDays - 1));
            expect(scope.request.startDate.getDate()).toEqual(today.getDate());
            expect(scope.request.endDate.getDate()).toEqual(future.getDate());
            expect(scope.request.forDays).toEqual(request.forDays);
        });

        it('should set date for negative days', function() {
            request = {
                startDate: null,
                endDate: null,
                forDays: -5
            };
            controller(request);
            var today = new Date();
            var past = new Date();
            past.setDate(today.getDate() + request.forDays);
            expect(scope.request.startDate.getDate()).toEqual(past.getDate());
            expect(scope.request.endDate.getDate()).toEqual(today.getDate());
            expect(scope.request.forDays).toEqual(request.forDays);
        });
    });

    describe('Affected cases', function() {
        beforeEach(function() {
            request = {
                requestId: 1,
                noOfAffectedCases: null,
                startDate: new Date('20160825'),
                endDate: new Date('20160826')
            };
        });

        it('should not call service if noOfCases feature not available', function() {
            canCalculateAffectedCases = false;
            controller(request);
            expect(affectedCasesService.getAffectedCases).not.toHaveBeenCalled();
        });

        it('should not call service if noOfCases is supplied', function() {
            request.noOfAffectedCases = 1;
            controller(request);
            expect(affectedCasesService.getAffectedCases).not.toHaveBeenCalled();
        });

        it('should call service if noOfCases supplied is null', function() {

            controller(request);
            expect(scope.runMode.type).toBe(1);
            expect(affectedCasesService.getAffectedCases).toHaveBeenCalledWith(request.requestId);
        });

        it('should call service if noOfCases is not supplied', function() {
            request = {
                requestId: 1,
                startDate: new Date('20160825'),
                endDate: new Date('20160826')
            };
            controller(request);
            expect(scope.runMode.type).toBe(1);
            expect(affectedCasesService.getAffectedCases).toHaveBeenCalledWith(request.requestId);
        });
    });
});