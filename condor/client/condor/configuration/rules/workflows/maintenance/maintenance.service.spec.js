describe('inprotech.configuration.rules.workflows.workflowsMaintenanceService', function() {
    'use strict';

    var service, httpMock, charsService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');

        module(function() {
            httpMock = test.mock('$http', 'httpMock');
            charsService = test.mock('workflowsCharacteristicsService');
        });

        inject(function(workflowsMaintenanceService) {
            service = workflowsMaintenanceService;
        });
    });


    it('getCharacteristics should pass correct parameters', function() {
        service.getCharacteristics(-1);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/characteristics');
    });

    it('save should pass correct parameters', function() {
        service.save(-1, 'a');
        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/rules/workflows/-1', 'a');
    });

    it('picklistEquals', function() {
        charsService.isCharacteristicField.returnValue = true;

        expect(service.picklistEquals('action', null, null)).toBe(true);

        expect(service.picklistEquals('action', {
            key: 1
        }, {
            key: 1
        })).toBe(true);

        expect(service.picklistEquals('action', {
            key: 1
        }, {
            key: 2
        })).toBe(false);

        expect(service.picklistEquals('action', {
            key: 1
        }, null)).toBe(false);

        expect(service.picklistEquals('action', null, {
            key: 1
        })).toBe(false);

        expect(service.picklistEquals('action', null, {
            key: null
        })).toBe(true);
    });

    it('createSaveRequestDataForCharacteristics', function() {
        var data = service.createSaveRequestDataForCharacteristics({
            action: {
                code: 1
            }
        });
        expect(data.action).toBe(1);
    });

    describe('getDescendantsMethod', function() {
        it('should pass criteriaId', function() {
            httpMock.get.returnValue = 'data';
            var result = service.getDescendants(123);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/123/descendants');
            expect(result).toEqual('data');
        });
    });

    describe('resetWorkflowMethod', function() {
        it('should pass criteria Id and inherit descendants option', function() {
            httpMock.put.returnValue = 'data';
            var result = service.resetWorkflow(123, true);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/rules/workflows/123/reset?applyToDescendants=true');
            expect(result).toEqual('data');
        });

        it('should pass update name responsible option', function() {
            httpMock.put.returnValue = 'data';
            var result = service.resetWorkflow(123, false, true);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/rules/workflows/123/reset?applyToDescendants=false&updateRespNameOnCases=true');
            expect(result).toEqual('data');
        })
    });
});