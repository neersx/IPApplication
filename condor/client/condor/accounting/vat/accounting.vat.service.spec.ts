namespace inprotech.accounting.vat {
    'use strict';

    declare var test: any;

    describe('inprotech.accounting.vat.service', () => {
        let service: () => IVatReturnsService, http, store, _$rootScope, promiseMock;
        let s: IVatReturnsService;

        beforeEach(() => {
            angular.mock.module(() => {
                http = test.mock('$http', 'httpMock');
                store = test.mock('store', 'storeMock');
                promiseMock = test.mock('promise', 'promiseMock');
            });
            angular.mock.module('inprotech.accounting.vat');
        });

        beforeEach(inject(($rootScope, $httpBackend) => {
            _$rootScope = $rootScope.$new();
            let $injector: ng.auto.IInjectorService = angular.injector([
                'inprotech.mocks'
            ]);
            let headerService: any = $injector.get('HmrcHeadersBuilderServiceMock');

            headerService.resolve = jasmine.createSpy().and.returnValue({
                'x-inprotech-current-timezone': 'UTC+10:00',
                'x-inprotech-client-device-id': 'fgdfgdfg'
            });

            service = () => {
                return new VatReturnsService(http, store, headerService);
            };
        }));

        it('calls the server to return obligations', () => {
            let filter = {
                taxCode: '123',
                fromDate: '2019-01-01',
                toDate: '2019-03-03'
            };
            s = service();

            http.get = promiseMock.createSpy({data: {
                result: {
                    readyToRedirect: 'ok'
                }
            }}).and.callThrough();
            s.getObligations(filter);
            expect(http.get).toHaveBeenCalledWith(
                'api/accounting/vat/obligations', {
                    params: {
                        q: JSON.stringify(filter)
                    },
                    headers: {
                        'x-inprotech-current-timezone': 'UTC+10:00',
                        'x-inprotech-client-device-id': 'fgdfgdfg'
                    }
                }
            );
        });

        it('returns data', () => {
            let filter = {
                taxCode: '123',
                fromDate: '2019-01-01',
                toDate: '2019-03-03'
            };
            http.get = promiseMock.createSpy({
                data: {
                    data: {
                        status: 'ok',
                        data: [1, 2, 3]
                    }
                },
                status: 200
            }).and.callThrough();
            s = service();
            let result = s.getObligations(filter);
            _$rootScope.$digest();
            expect(result.data.length).toBe(3);
        });

        it('calls the server to submit VAT return', () => {
            let data = {
                taxCode: '123',
                fromDate: '2019-01-01',
                toDate: '2019-03-03'
            };
            s = service();
            s.submitVatData(data);
            expect(http.post).toHaveBeenCalledWith('api/accounting/vat/submit', {
                taxCode: '123',
                fromDate: '2019-01-01',
                toDate: '2019-03-03'
            }, ({
                headers: {
                    'x-inprotech-current-timezone': 'UTC+10:00',
                    'x-inprotech-client-device-id': 'fgdfgdfg'
                }
            }));
        });

        it('calls the server to get the vat return data', () => {
            let data = {
                taxCode: '123',
                fromDate: '2019-01-01',
                toDate: '2019-03-03'
            };
            s = service();
            s.getReturn(data);

            expect(http.get).toHaveBeenCalledWith('api/accounting/vat/vatreturn', {
                params: {
                    q: JSON.stringify({
                        'taxCode': '123',
                        'fromDate': '2019-01-01',
                        'toDate': '2019-03-03'
                    })
                },
                headers: {
                    'x-inprotech-current-timezone': 'UTC+10:00',
                    'x-inprotech-client-device-id': 'fgdfgdfg'
                }
            });
        });
    });
}