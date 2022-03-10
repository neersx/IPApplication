namespace inprotech.portfolio.cases {
    export class CaseSearchPagingInfoMock implements IPagingInfo {

        public viewStartIndex?: number;
        public requestStartPage?: number;
        public requestEndPage?: number;
        public requestKeysFromServer?: boolean;
        public rowsPerBlock?: number;

        constructor() {
            spyOn(this, 'setPagingInfo').and.callThrough();
        }

        setPagingInfo = (a: any, b: number, c: number) => { };
    }

    angular.module('inprotech.mocks')
        .service('CaseSearchPagingInfoMock', CaseSearchPagingInfoMock);

}