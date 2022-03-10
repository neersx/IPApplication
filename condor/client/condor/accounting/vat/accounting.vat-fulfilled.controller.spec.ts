namespace inprotech.accounting.vat {
    describe('should show the vat fulfilled dialog', () => {
        let controller: () => AccountingViewVatReturnController,
            service: any,
            uibModalInstance: any,
            promiseMock: any,
            dateService: any,
            window: any;

        beforeEach(() => {
            angular.mock.module('inprotech.accounting.vat');
            inject(($q: ng.IQService, $window: ng.IWindowService) => {
                let $injector: ng.auto.IInjectorService = angular.injector([
                    'inprotech.mocks',
                    'inprotech.mocks.core'
                ]);
                dateService = $injector.get('dateServiceMock');
                uibModalInstance = $injector.get('ModalInstanceMock');
                promiseMock = $injector.get < any > ('promiseMock');
                service = $injector.get('VatReturnsServiceMock');
                let options = {
                    entityNameNo: 1,
                    fromDate: new Date(),
                    toDate: new Date(),
                    entityName: 'entity',
                    entityTaxCode: 'taxcode',
                    periodKey: '18A2',
                    selectedEntitiesNames: 'entity, entity1.'
                }
                let q = $q;
                window = $window;
                spyOn(window, 'open').and.callThrough();
                controller = () => {
                    let c = new AccountingViewVatReturnController(
                        uibModalInstance,
                        service,
                        options,
                        dateService,
                        q,
                        window
                    );
                    return c;
                };
            });
        });

        describe('initialize', () => {
            it('should initialise the modal', () => {
                service.getReturn = promiseMock.createSpy({
                    vatResponse: {
                        processingDate: new Date(),
                        formBundleNumber: 1111,
                        paymentIndicator: 'BANK'
                    },
                    vatReturnData: {
                        status: 'ok',
                        data: [1, 2, 3, 4, 5, 6, 7, 8, 9]
                    }
                });
                dateService.format = promiseMock.createSpy(new Date());

                let c = controller();
                expect(c.fromDate).toBeDefined();
                expect(c.toDate).toBeDefined();
                expect(c.entityName).toBeDefined();
                expect(c.entityNameNo).toBeDefined();
                expect(c.entityTaxCode).toBeDefined();
                expect(c.selectedEntitiesNames).toBeDefined();
            });
        });

        describe('load', () => {
            it('page loads correctly', () => {
                service.getReturn = promiseMock.createSpy({
                    vatResponse: {
                        processingDate: new Date(),
                        formBundleNumber: 1111,
                        paymentIndicator: 'BANK'
                    },
                    vatReturnData: {
                        status: 'ok',
                        data: [1.11, 2.22, 3.33, 4.44, 5.55, 6.66, 7.77, 8.88, 9.99]
                    }
                });
                dateService.format = promiseMock.createSpy(new Date());

                let c = controller();

                expect(c.vatValues[0]).toEqual(String(1.11));
                expect(c.vatValues[1]).toEqual(String(2.22));
                expect(c.vatValues[2]).toEqual(String(3.33));
                expect(c.vatValues[3]).toEqual(String(4.44));
                expect(c.vatValues[4]).toEqual(String(5.55));
                expect(c.vatValues[5]).toEqual(String(6.66));
                expect(c.vatValues[6]).toEqual(String(7.77));
                expect(c.vatValues[7]).toEqual(String(8.88));
                expect(c.vatValues[8]).toEqual(String(9.99));
            });
        });

        describe('export button', () => {
            it('should call the export function with correct parameters', () => {
                service.getReturn = promiseMock.createSpy({
                    vatResponse: {
                        processingDate: new Date(),
                        formBundleNumber: 1111,
                        paymentIndicator: 'BANK'
                    },
                    vatReturnData: {
                        status: 'ok',
                        data: [1.11, 2.22, 3.33, 4.44, 5.55, 6.66, 7.77, 8.88, 9.99]
                    }
                });
                window.open = promiseMock.createSpy();
                let c = controller();
                let pdfId = 'xxx123456xxx';
                c.pdfId = pdfId
                c.fromDate = '20-11-2019';
                c.toDate = '20-12-2019';
                const fileName = 'entity 20-11-2019-to-20-12-2019';

                c.exportToPdf();

                expect(window.open).toHaveBeenCalledWith('accounting/vat/' + c.pdfId + '/exportToPdf/' + fileName);
            });
        });
    });
}