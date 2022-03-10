'use strict'
namespace inprotech.portfolio.cases {
    declare var test: any;
    describe('case view Designated Jurisdiction service', function () {

        let service: ICaseViewDesignationsService, http;

        beforeEach(function () {
            angular.mock.module(function () {
                http = test.mock('$http', 'httpMock');
            });
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function () {
            inject(function (caseViewDesignationsService) {
                service = caseViewDesignationsService;
            });
        });

        it('returns designated jusrisdictions from server', function () {
            expect(service).toBeDefined();
            service.getCaseViewDesignatedJurisdictions(1, { skip: 0 });
            expect(http.get).toHaveBeenCalledWith('api/case/1/designatedjurisdiction', {
                params: {
                    params: JSON.stringify({ skip: 0 })
                }
            });
        });

        it('returns designated jusrisdictions filters', function () {
            expect(service).toBeDefined();
            let alreadyAppliedFilters = [{ field: 'alreadyAppliedFilters' }];
            service.getColumnFilterData(1, { field: 'a' }, alreadyAppliedFilters);
            expect(http.get).toHaveBeenCalledWith('api/case/1/designatedjurisdiction/filterData/a', {
                params: {
                    columnFilters: JSON.stringify(alreadyAppliedFilters)
                }
            });
        });

        it('returns designated jusrisdictions details', function () {
            expect(service).toBeDefined();
            service.getSummary(1);
            expect(http.get).toHaveBeenCalledWith('api/case/1/designationdetails');
        });
    });
}