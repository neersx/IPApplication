describe('inprotech.processing.policing.requestReminderHelper', function() {
    'use strict';

    var helper, request, promiseMock;

    beforeEach(function() {
        module('inprotech.processing.policing');
        var $injector = angular.injector(['inprotech.mocks.core']);
        promiseMock = $injector.get('promiseMock');
    });

    beforeEach(inject(function(requestReminderHelper) {

        helper = requestReminderHelper;

        request = {
            startDate: null,
            endDate: null,
            forDays: null
        };

        helper.init(request);
    }));
    describe('setForDays', function() {
        var startDate, endDate;
        beforeEach(function() {
            startDate = new Date('2016-10-05');
            endDate = new Date('2016-10-08');
        });

        it('should setForDays automatically when start and end date are provided', function() {
            request.forDays = 1;
            helper.setForDays(startDate, endDate);
            expect(request.forDays).toBe(4);
        });

        it('should not setForDays automatically if start or end date is not provided', function() {
            request.forDays = 2;
            helper.setForDays(null, endDate);
            expect(request.forDays).toBe(2);

            helper.setForDays(startDate, null);
            expect(request.forDays).toBe(2);
        });

        it('should not setForDays automatically on date change if for Days are negative', function() {
            request.forDays = -2;
            helper.setForDays(startDate, endDate);
            expect(request.forDays).toBe(-2);
        });

        it('should reset setForDays if end date is less than start date', function() {
            request.forDays = 2;
            helper.setForDays(endDate, startDate);
            expect(request.forDays).toBeNull();
        });
    });

    describe('setDatesValidityByDays', function() {
        var form;
        var errorKey = 'policing.request.maintenance.sections.eventsReminder.errors.daysNegative';
        beforeEach(function() {
            form = {
                startDate: {
                    $setValidity: promiseMock.createSpy()
                },
                endDate: {
                    $setValidity: promiseMock.createSpy()
                }
            };
        });

        it('should set dates as invalid if negative days are entered', function() {
            request.startDate = new Date('2016-10-05');
            request.endDate = new Date('2016-10-08');
            request.forDays = -2;

            helper.setDatesValidityByDays(form);
            expect(form.startDate.$setValidity).toHaveBeenCalledWith(errorKey, false);
            expect(form.endDate.$setValidity).toHaveBeenCalledWith(errorKey, false);
        });         

         it('should set dates as invalid if start date is entered when negative days are already entered', function() {
            request.forDays = -2;
            helper.setDatesValidityByDays(form,'startDate',new Date('2016-10-05'));
            expect(form.startDate.$setValidity).toHaveBeenCalledWith(errorKey, false);

            expect(form.endDate.$setValidity).not.toHaveBeenCalled();
        });

        it('should set dates as invalid if endDate date is entered when negative days are already entered', function() {
            request.forDays = -2;
            helper.setDatesValidityByDays(form,'endDate',new Date('2016-10-05'));
            expect(form.endDate.$setValidity).toHaveBeenCalledWith(errorKey, false);

            expect(form.startDate.$setValidity).not.toHaveBeenCalled();
        });

        it('should set dates as valid if positive days are entered', function() {
            request.startDate = new Date('2016-10-05');
            request.endDate = new Date('2016-10-08');
            request.forDays = 2;

            helper.setDatesValidityByDays(form);
            expect(form.startDate.$setValidity).toHaveBeenCalledWith(errorKey, true);
            expect(form.endDate.$setValidity).toHaveBeenCalledWith(errorKey, true);
        });
    });
});