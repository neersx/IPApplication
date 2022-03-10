namespace inprotech.portfolio.cases {
    export class CaseViewEfilingServiceMock implements ICaseviewEfilingService {
        constructor() {
            spyOn(this, 'getPackages').and.callThrough();
            spyOn(this, 'getPackageFiles').and.callThrough();
            spyOn(this, 'getEfilingFileData').and.callThrough();
            spyOn(this, 'getPackageHistory').and.callThrough();
        }
        getPackages(caseKey: number, queryParams: any): void {}
        getPackageFiles(caseKey: number, exchangeId: number, packageSequence: number): void {}
        getEfilingFileData(caseKey: number, packageSequence: number, packageFileSequence: number, exchangeId: number): void {}
        getPackageHistory(caseKey: number, exchangeId: number, queryParams: any): void {}
    }
    angular
        .module('inprotech.mocks')
        .service('CaseViewEfilingServiceMock', CaseViewEfilingServiceMock);
}