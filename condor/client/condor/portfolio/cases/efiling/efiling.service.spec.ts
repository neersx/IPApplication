namespace inprotech.portfolio.cases {
    'use strict';

    declare var test: any;
    describe('inprotech.portfolio.cases.efilingService', () => {

        let service: () => ICaseviewEfilingService, http;
        let s: ICaseviewEfilingService;

        beforeEach(() => {
            angular.mock.module(() => {
                http = test.mock('$http', 'httpMock');
            });
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(inject(() => {
            service = () => {
                return new CaseviewEfilingService(http);
            };
        }));

        it('calls server to get package details', () => {
            let caseKey = 123,
                params = {
                    prop: 'value'
                };

            s = service();
            s.getPackages(caseKey, params);
            expect(http.get).toHaveBeenCalledWith('api/case/123/efiling', {
                params: {
                    params: JSON.stringify(params)
                }
            });
        });

        it('calls server to get package files', () => {
            let caseKey = 45,
                exchangeId = 20,
                packageSequence = 1

            s = service();
            s.getPackageFiles(caseKey, exchangeId, packageSequence);
            expect(http.get).toHaveBeenCalledWith('api/case/45/efilingPackageFiles', {
                params: {
                    package: JSON.stringify({
                        exchangeId: exchangeId,
                        packageSequence: packageSequence
                    })
                }
            });
        });
    });
}