'use strict'
namespace inprotech.portfolio.cases {
    declare var test: any;
    describe('cases Debtor Restrictions service', function () {

        let service: IDebtorRestrictionsService, http;

        beforeEach(function () {
            angular.mock.module(function () {
                http = test.mock('$http', 'httpMock');
            });
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function () {
            inject(function (debtorRestrictionsService) {
                service = debtorRestrictionsService;
            });
        });

        it('returns name restrictions from server', function () {
            expect(service).toBeDefined();
            http.get.returnValue = {
                data: [{id: 1}]
            };
            service.getRestrictions(1);
            expect(http.get).toHaveBeenCalledWith('api/names/restrictions', {
                params: {
                    ids: '1'
                }
            });
        });

        it('returns cached name restrictions from server', function () {
            expect(service).toBeDefined();
            http.get.returnValue = {
                data: [{id: 1}]
            };

            let a: any, b: any, c: any;

            service.getRestrictions(1)
                .then((r1) => {
                    a = r1;
                    service.getRestrictions(1)
                        .then((r2) => {
                            b = r2;
                            service.getRestrictions(1)
                            .then((r3) => {
                                c = r3;
                            });
                        });
                });
            expect(http.get).toHaveBeenCalledWith('api/names/restrictions', {
                params: {
                    ids: '1'
                }
            });

            expect(http.get.calls.count()).toEqual(1);
            expect(a).toEqual(b);
            expect(b).toEqual(c);
        });
    });
}