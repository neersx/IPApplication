namespace inprotech.portfolio.cases {
    export class CaseViewImagesServiceMock implements ICaseViewImagesService {
        constructor() {
            spyOn(this, 'getCaseImages').and.callThrough();
        }
        getCaseImages(caseKey: number): void {}
    }
    angular
        .module('inprotech.mocks')
        .service('CaseViewImagesServiceMock', CaseViewImagesServiceMock);
}