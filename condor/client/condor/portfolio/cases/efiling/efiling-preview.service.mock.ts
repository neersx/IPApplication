namespace inprotech.portfolio.cases {
  export class EFilingPreviewMock implements IEfilingPreview {
    constructor() {
      spyOn(this, 'preview').and.callThrough();
    }
    preview(response: any): void {}
  }
  angular
    .module('inprotech.mocks')
    .service('EFilingPreviewMock', EFilingPreviewMock);
}
