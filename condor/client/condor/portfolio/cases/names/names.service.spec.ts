'use strict'
namespace inprotech.portfolio.cases {
    declare var test: any;
    describe('case view names service', () => {

        let service: ICaseviewNamesService, http;

        beforeEach(() => {
            angular.mock.module(function() {
                http = test.mock('$http', 'httpMock');
            });
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(() => {
            inject((caseviewNamesService: ICaseviewNamesService) => {
                service = caseviewNamesService;
            });
        });

        it('returns case names from server', () => {
            service.getNames(1, [], 2, {
                skip: 0
            });
            expect(http.get).toHaveBeenCalledWith('api/case/1/names', {
                params: {
                    params: JSON.stringify({
                        skip: 0
                    }),
                    screenCriteriaKey: 2,
                    nameTypes: JSON.stringify({
                        keys: []
                    })
                }
            });
        });

        it('returns email template from server with sequence provided', () => {
            service.getFirstEmailTemplate(1, 'a', 0);
            expect(http.get).toHaveBeenCalledWith('api/case/1/names/email-template', {
                params: {
                    params: JSON.stringify({
                        caseKey: 1,
                        nameType: 'a',
                        sequence: 0
                    }),
                    resolve: false
                }
            });
        });

        it('returns email template from server without sequence provided', () => {
            service.getFirstEmailTemplate(1, 'a');
            expect(http.get).toHaveBeenCalledWith('api/case/1/names/email-template', {
                params: {
                    params: JSON.stringify({
                        caseKey: 1,
                        nameType: 'a',
                        sequence: null
                    }),
                    resolve: true
                }
            });
        });
    });
}