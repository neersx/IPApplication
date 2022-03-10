namespace inprotech.accounting.vat {
    export class VatReturnsServiceMock implements IVatReturnsService {
        public returnValues: any;

        constructor() {
            spyOn(this, 'initialiseHmrcHeaders').and.callThrough();
            spyOn(this, 'getObligations').and.callThrough();
            spyOn(this, 'getVatData').and.callThrough();
            spyOn(this, 'submitVatData').and.callThrough();
            spyOn(this, 'save').and.callThrough();
            spyOn(this, 'getReturn').and.callThrough();
            spyOn(this, 'getLogs').and.callThrough();
        }
        initialiseHmrcHeaders(data: any): ng.IPromise<any> { return }
        getObligations(data: any): void {}
        getVatData(vatBoxNumber: number, entityNameNo: number, fromDate: Date, toDate: Date): void {}
        submitVatData(data: any): void {}
        save(data: any): void {}
        getReturn(data: any): void {}
        getLogs(entityId: number, periodId: string): void {}
    }
    angular
        .module('inprotech.mocks')
        .service('VatReturnsServiceMock', VatReturnsServiceMock);
}