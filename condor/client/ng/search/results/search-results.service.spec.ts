import { CaseNavigationService } from 'cases/core/case-navigation.service';
import { of } from 'rxjs';
import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import * as _ from 'underscore';
import { SearchResultsViewData } from './search-results.data';
import { SearchResultsService } from './search-results.service';

describe('CaseSearchService', () => {
    let service: SearchResultsService;
    let httpClientSpy;
    beforeEach(() => {
        httpClientSpy = { get: jest.fn(), post: jest.fn() };
        service = new SearchResultsService(httpClientSpy, new CaseNavigationService(httpClientSpy));
        SearchTypeConfigProvider.savedConfig = { baseApiRoute: 'api/search/case/' } as any;
    });
    it('should exist', () => {
        expect(service).toBeDefined();
    });

    it('should call getCaseSearchResultsViewData', () => {
        const response: SearchResultsViewData = new SearchResultsViewData();
        response.queryKey = 1;
        const params = {
            queryKey: 1,
            q: null,
            filter: null,
            searchQueryKey: false,
            queryContext: 2
        };
        httpClientSpy.get.mockReturnValue(of(response));
        service.getSearchResultsViewData(params).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result.queryKey).toBe(response.queryKey);
            }
        );
    });
    it('should call getCaseEditedSavedSearch', () => {
        const queryKey = 1;
        const params = {
            skip: 0,
            take: 20
        };
        httpClientSpy.post.mockReturnValue(of([]));

        service.getEditedSavedSearch$(queryKey, null, params, null, 2);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });

    });

    it('should call getColumnFilterData with filter of string datatype', () => {
        const queryKey = 1;
        const params = {
            skip: 0,
            take: 20
        };
        const column = 'countryname__7_';
        const filter = '<Search></Search>';
        httpClientSpy.post.mockReturnValue(of([]));
        service.getColumnFilterData(filter, column, params, queryKey, null, 2).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(httpClientSpy.Post).toHaveBeenCalledWith('api/search/case/filterData', jasmine.objectContaining(_.extend({
                    criteria: { XmlSearchRequest: filter }
                }, column, params, queryKey, null, 2)));
            }
        );
    });

    it('should call getColumnFilterData without filter of string datatype', () => {
        const queryKey = 1;
        const params = {
            skip: 0,
            take: 20
        };
        const column = 'countryname__7_';
        const filter = { searchRequest: {}, dueDateFilter: null };
        httpClientSpy.post.mockReturnValue(of([]));
        service.getColumnFilterData(filter, column, params, queryKey, null, 2).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(httpClientSpy.Post).toHaveBeenCalledWith('api/search/case/filterData', jasmine.objectContaining(_.extend({
                    criteria: { searchRequest: {}, dueDateFilter: null }
                }, column, params, queryKey, null, 2)));
            }
        );
    });

    it('should call getCaseSearchResultsViewData and get globalProcessKey, backgroundProcessResultTitle, presentationType if querykey is null', () => {
        const response: SearchResultsViewData = new SearchResultsViewData();
        response.queryKey = 1;
        const params = {
            queryKey: null,
            q: null,
            filter: null,
            searchQueryKey: false,
            presentationType: 'presentationType',
            globalProcessKey: 1,
            backgroundProcessResultTitle: 'title',
            queryContext: 2
        };
        httpClientSpy.get.mockReturnValue(of(response));
        service.getSearchResultsViewData(params).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result.presentationType).toBe(params.presentationType);
                expect(result.globalProcessKey).toBe(params.globalProcessKey);
                expect(result.backgroundProcessResultTitle).toBe(params.backgroundProcessResultTitle);
            }
        );
    });

    it('should call getCaseSearchResultsViewData and it should clear globalProcessKey, backgroundProcessResultTitle, presentationType if querykey is not null', () => {
        const response: SearchResultsViewData = new SearchResultsViewData();
        response.queryKey = 1;
        const params = {
            queryKey: 1,
            q: null,
            filter: null,
            searchQueryKey: false,
            presentationType: 'presentationType',
            globalProcessKey: 1,
            backgroundProcessResultTitle: 'title',
            queryContext: 2
        };
        httpClientSpy.get.mockReturnValue(of(response));
        service.getSearchResultsViewData(params).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result.presentationType).toBe(null);
                expect(result.globalProcessKey).toBe(null);
                expect(result.backgroundProcessResultTitle).toBe(null);
            }
        );
    });
});
