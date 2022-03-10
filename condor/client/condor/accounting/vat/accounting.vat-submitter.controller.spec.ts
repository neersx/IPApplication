namespace inprotech.accounting.vat {
    describe('should show the vat submission dialog', () => {
        let controller: () => AccountingVatSubmitterController,
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
                    selectedEntitiesNames: 'entity, entity1.'
                }
                let q = $q;
                window = $window;
                spyOn(window, 'open').and.callThrough();
                controller = () => {
                    let c = new AccountingVatSubmitterController(
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
                service.getVatData = promiseMock.createSpy({});
                dateService.format = promiseMock.createSpy(new Date());
                spyOn(Array.prototype, 'reduce').and.callThrough();
                let c = controller();
                expect(c.fromDate).toBeDefined();
                expect(c.toDate).toBeDefined();
                expect(c.entityName).toBeDefined();
                expect(c.entityNameNo).toBeDefined();
                expect(c.entityTaxCode).toBeDefined();
                expect(c.selectedEntitiesNames).toBeDefined();
                expect(Array.prototype.reduce).toHaveBeenCalled();
            });
        });

        describe('calculations', () => {
            it('should be correctly calculate vatBox3 and vatBox5', () => {
                service.getVatData = promiseMock.createSpy({});
                let c = controller();
                c.vatValues[0] = 1.11;
                c.vatValues[1] = 1.11;
                c.vatBox3();
                expect(c.vatValues[2]).toEqual(String(2.22));
                c.vatValues[3] = 1.11;
                c.vatBox5();
                expect(c.vatValues[4]).toEqual(String(1.11));

                c.vatValues[3] = 3.33;
                c.vatBox5();
                expect(c.vatValues[4]).toEqual(String(1.11));
            });
        });

        describe('close', () => {
            it('should return success if submitted successfully', () => {
                uibModalInstance.close = promiseMock.createSpy();
                let c = controller();
                let successResponse = {
                    chargeRefNumber: 155174814544,
                    formBundleNumber: 383333,
                    paymentIndicator: 'BANK',
                    processingDate: '2019-03-05T01:09:06.890Z'
                };
                c.responseSuccess = successResponse;
                c.responseError = { error: 'error-message'};

                c.close();

                expect(uibModalInstance.close).toHaveBeenCalledWith(successResponse);
                expect(uibModalInstance.close).not.toHaveBeenCalledWith(c.responseError);
            });
        });

        describe('export button', () => {
            it('should call the export function with correct parameters', () => {
                let c = controller();
                let pdfId = 'xxx123456xxx';
                c.pdfId = pdfId;
                c.fromDate = '20-11-2019';
                c.toDate = '20-12-2019';
                const fileName = 'VAT Group 20-11-2019-to-20-12-2019';

                window.open = promiseMock.createSpy();
                c.export();

                expect(window.open).toHaveBeenCalledWith('accounting/vat/' + c.pdfId + '/exportToPdf/' + fileName);
            });
        });
    });
}