describe('inprotech.configuration.rules.workflows.workflowsDueDateCalcService', function() {
    'use strict';

    var service, httpMock;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector([
                'inprotech.mocks.configuration.rules.workflows',
                'inprotech.mocks'
            ]);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
        inject(function(workflowsDueDateCalcService) {
            service = workflowsDueDateCalcService;
        });
    });

    describe('should initialize setting view model correctly based on data from backend', function() {
        var data;

        beforeEach(function() {
            data = {};
        });

        it('should set default', function() {
            service.initSettingsViewModel(data);
            expect(data.dateToUse).toEqual('E');
            expect(data.recalcEventDate).toEqual(false);
            expect(data.isSaveDueDate).toEqual(false);
            expect(data.extendDueDate).toEqual(false);
            expect(data.extendDueDateOptions).toEqual({ type: null, value: null });
        });
    });

    describe('getSettingsForSave', function() {
        it('should get period and period type when extending due date', function() {
            var data = {
                extendDueDate: true,
                extendDueDateOptions: {
                    value: 12,
                    type: 'D'
                }
            };
            var result = service.getSettingsForSave(data);
            expect(result.extendPeriod).toEqual(12);
            expect(result.extendPeriodType).toEqual('D');
        });

        it('should not get period and type when extend due date unchecked', function() {
            var data = {
                extendDueDate: false,
                extendDueDateOptions: {
                    value: 12,
                    type: 'D'
                }
            };
            var result = service.getSettingsForSave(data);
            expect(result.extendPeriod).toBeUndefined();
            expect(result.extendPeriodType).toBeUndefined();
        });
    });

    it('getDueDateCalcs should pass correct parameters', function() {
        service.getDueDateCalcs(-1, -2);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/events/-2/duedates');
    });
});
