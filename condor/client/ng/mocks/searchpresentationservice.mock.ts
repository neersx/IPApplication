export class SearchPresentationServiceMock {
    getSearchPresentationData = jest.fn().mockReturnValue({
        selectedColumns: [],
        availableColumnsForSearch: []
    });
    setSearchPresentationData = jest.fn();
}