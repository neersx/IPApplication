namespace inprotech.portfolio.cases {
    export class CaseSharedServiceMock implements ICaseSharedService {
        lastSearch?: any;
        ids?: any;
        lastViewedIndex?: number;
        totalRows?: number;

        constructor() {
            spyOn(this, 'initIds').and.callThrough();
            spyOn(this, 'addToExistingIds').and.callThrough();
            spyOn(this, 'fetchNext').and.callThrough();

        }
        initIds(ids: any): void { }
        addToExistingIds(ids: any): void { }
        fetchNext(currentIndex: number): void { }
        getCaseKeyFromRowKey(currentIndex: Number): Number { return 1}
        createRowKeyCaseKeyMappings(data: any, skipCount: number): any[] { return []}
    }
    angular.module('inprotech.mocks').service('CaseSharedServiceMock', CaseSharedServiceMock);
}