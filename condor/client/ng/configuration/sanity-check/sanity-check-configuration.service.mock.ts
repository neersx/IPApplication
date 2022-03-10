import { of } from 'rxjs/internal/observable/of';

export class SanityCheckConfigurationServiceMock {
    setSearchData = jest.fn();
    getSearchData = jest.fn();
    getNavData = jest.fn();
    getViewData$ = jest.fn(() => of(true));
    search$ = jest.fn().mockReturnValue(of([]));
    deleteSanityCheck$ = (matchType: 'case' | 'name', ids: Array<any>) => jest.fn(() => of(true));
}
