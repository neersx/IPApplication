export class CaseNavigationServiceMock {
    init = jest.fn();
    tempReturnNextRecordSetFromCache = jest.fn();
    getNavigationData = jest.fn();
    getCaseKeyFromRowKey = jest.fn();
    getSearch$ = jest.fn();
    setNavigationData = jest.fn();
    fetchNext$ = jest.fn();
    getCurrentPageIndex = jest.fn();
    caseSavedSearch$ = jest.fn();
    clearLoadedData = jest.fn();
}