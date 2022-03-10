describe('inprotech.configuration.rules.workflows.workflowInheritanceService', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });

        inject(function(workflowInheritanceService) {
            service = workflowInheritanceService;
        });
    });

    it('getCriteriaDetail should convert data from characteristic service', function() {
        httpMock.get.returnValue = {
            office: {
                value: 'office'
            },
            jurisdiction: {
                value: 'jurisdiction'
            },
            caseType: {
                value: 'caseType'
            },
            propertyType: {
                value: 'propertyType'
            },
            caseCategory: {
                value: 'caseCategory'
            },
            subType: {
                value: 'subType'
            },
            basis: {
                value: 'basis'
            },
            dateOfLaw: {
                value: 'dateOfLaw'
            },
            action: {
                value: 'action'
            },
            isLocalClient: true,
            inUse: true,
            isProtected: true
        };

        var r = service.getCriteriaDetail(1);

        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/1/characteristics');
        expect(r.office).toBe('office');
        expect(r.jurisdiction).toBe('jurisdiction');
        expect(r.caseType).toBe('caseType');
        expect(r.propertyType).toBe('propertyType');
        expect(r.caseCategory).toBe('caseCategory');
        expect(r.subType).toBe('subType');
        expect(r.basis).toBe('basis');
        expect(r.dateOfLaw).toBe('dateOfLaw');
        expect(r.action).toBe('action');
        expect(r.localOrClient).toBe('Local clients');
        expect(r.inUse).toBe(true);
        expect(r.isProtected).toBe(true);
    });

    it('breakInheritance should pass correct parameters', function() {
        service.breakInheritance(-123);
        expect(httpMock.delete).toHaveBeenCalledWith('api/configuration/rules/workflows/-123/inheritance');
    });

    describe('when changeParentInheritance is invoked: ', function() {
        var newParentId, replaceCommonRules, params;

        beforeEach(function() {
            newParentId = -456;
            replaceCommonRules = true;
            params = {
                newParent: newParentId,
                replaceCommonRules: replaceCommonRules
            };
        });

        it('should pass correct parameters', function() {
            service.changeParentInheritance(-123, newParentId, replaceCommonRules);
            expect(httpMock.put).toHaveBeenCalledWith(
                'api/configuration/rules/workflows/-123/inheritance',
                params
            );
        });

        it('should return correct data', function() {
            httpMock.put.returnValue = 'abc';
            var result = service.changeParentInheritance(-123, newParentId, replaceCommonRules);
            expect(result).toEqual('abc');
        });
    });

    it('deleteCriteria calls correct api', function(){
        service.deleteCriteria(111);
        expect(httpMock.delete).toHaveBeenCalledWith('api/configuration/rules/workflows/111')
    });

    it('isCriteriaUsedByCase calls correct api', function(){
        httpMock.get.returnValue = true;

        var result = service.isCriteriaUsedByCase(111);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/111/usedByCase')
        expect(result).toBe(true);
    });
});
