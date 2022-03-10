'use strict'
namespace inprotech.portfolio.cases {
    declare var test: any;
    describe('case view case texts service', function () {

        let service: ICaseViewCaseTextsService, http;

        beforeEach(function () {
            angular.mock.module(function () {
                http = test.mock('$http', 'httpMock');
            });
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function () {
            inject(function (caseViewCaseTextsService) {
                service = caseViewCaseTextsService;
            });
        });

        it('returns case texts without filter from server', function () {
            expect(service).toBeDefined();
            service.getTexts(1, [], { skip: 0 });
            expect(http.get).toHaveBeenCalledWith('api/case/1/texts', {
                params: {
                    params: JSON.stringify({ skip: 0 }),
                    textTypes: JSON.stringify({ keys: []})
                }
            });
        });

        it('returns case texts with filter from server', function () {
            expect(service).toBeDefined();
            service.getTexts(1, ['CL', 'CB'], { skip: 0 });
            expect(http.get).toHaveBeenCalledWith('api/case/1/texts', {
                params: {
                    params: JSON.stringify({ skip: 0 }),
                    textTypes: JSON.stringify({ keys: ['CL', 'CB']})
                }
            });
        });

        it('returns case history', function () {
            expect(service).toBeDefined();
            service.getTextHistory(1, 'CB', 'EN');
            expect(http.get).toHaveBeenCalledWith('api/case/1/textHistory', {
                params: {
                    textClass: '',
                    language: 'EN',
                    textType: 'CB'
                }
            });
        });
    });
}