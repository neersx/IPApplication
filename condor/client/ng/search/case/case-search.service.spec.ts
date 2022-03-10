import { CaseNavigationService } from 'cases/core/case-navigation.service';
import { of } from 'rxjs';
import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { CaseSavedSearchData, CaseSearchViewData } from './case-search.data';
import { CaseSearchService } from './case-search.service';

describe('CaseSearchService', () => {
    let service: CaseSearchService;
    let httpClientSpy;
    beforeEach(() => {
        httpClientSpy = { get: jest.fn(), post: jest.fn() };
        service = new CaseSearchService(httpClientSpy, new CaseNavigationService(httpClientSpy));
        SearchTypeConfigProvider.savedConfig = { baseApiRoute: 'api/search/case/' } as any;
    });
    it('should exist', () => {
        expect(service).toBeDefined();
    });
    it('should call getCaseSearchViewData', () => {
        const response: CaseSearchViewData = new CaseSearchViewData();
        httpClientSpy.get.mockReturnValue(of(response));
        service.getCaseSearchViewData(false).subscribe(
            result => expect(result).toEqual(response)
        );
    });
    it('should call getCaseSearchViewData from service if called from case search results', () => {
        const response: CaseSearchViewData = new CaseSearchViewData();
        service.caseSearchData = {
            viewData: response,
            savedSearchData: null
        };
        const transitionParams: any = {
            returnFromCaseSearchResults: true
        };
        service.getCaseSearchViewData(transitionParams).subscribe(
            result => expect(result).toEqual(response)
        );
    });

    it('Delete saved search', () => {
        const response: any = true;
        httpClientSpy.get.mockReturnValue(of(response));
        service.DeletePresentation(response).subscribe(
            result => {
                expect(result).toEqual(response);
            }
        );
    });

    it('should call getCaseSummary', () => {
        const response: any = {};
        response.queryKey = 1;
        httpClientSpy.get.mockReturnValue(of(response));
        service.getCaseSummary(response.queryKey).subscribe(
            result => expect(result).toEqual(response)
        );
    });
    it('should call getCaseSavedSearchData', () => {
        const response: CaseSavedSearchData = new CaseSavedSearchData();
        response.queryKey = 1;
        httpClientSpy.get.mockReturnValue(of(response));
        const params = {
            queryKey: response.queryKey,
            returnFromCaseSearchResults: false,
            canEdit: true
        };
        service.getCaseSavedSearchData(params).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result.queryKey).toBe(response.queryKey);
            }
        );
    });
    it('should call getCaseSavedSearchData from service if called from case search results', () => {
        const response: CaseSavedSearchData = new CaseSavedSearchData();
        response.queryKey = 1;
        service.caseSearchData = {
            viewData: null,
            savedSearchData: response
        };
        const params = {
            queryKey: response.queryKey,
            returnFromCaseSearchResults: true,
            canEdit: true
        };
        service.getCaseSavedSearchData(params).subscribe(
            result => expect(result).toEqual(response)
        );
    });

    it('should call getCaseEditedSavedSearch', () => {
        const queryKey = 1;
        const params = {
            skip: 0,
            take: 20
        };
        httpClientSpy.post.mockReturnValue(of([]));

        service.getCaseEditedSavedSearch$(queryKey, null, params, null);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });

    });

    it('should call getGlobalCaseChangeResults', () => {
        const presentationType = 'presentationType';
        const globalProcessKey = 1;
        const params = {
            skip: 0,
            take: 20
        };
        httpClientSpy.post.mockReturnValue(of([]));

        service.getGlobalCaseChangeResults$(globalProcessKey, presentationType, params);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });

    });

    it('should batch event update', () => {
        const response: any = {};
        response.queryKey = 1;
        httpClientSpy.post.mockReturnValue(of(response));
        service.getBatchEventUpdateUrl('123,111').subscribe(
            result => expect(result).toEqual(response)
        );
    });
    it('should call getGlobalCaseChangeResults', () => {
        const presentationType = 'presentationType';
        const globalProcessKey = 1;
        const params = {
            skip: 0,
            take: 20
        };
        httpClientSpy.post.mockReturnValue(of([]));

        service.getGlobalCaseChangeResults$(globalProcessKey, presentationType, params);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });

    });

    it('should batch event update', () => {
        const response: any = {};
        response.queryKey = 1;
        httpClientSpy.post.mockReturnValue(of(response));
        service.getBatchEventUpdateUrl('123,111').subscribe(
            result => expect(result).toEqual(response)
        );
    });

    it('should call applySanityCheck', () => {
        httpClientSpy.post.mockReturnValue(of({ status: true }));
        service.applySanityCheck([123, 111]).subscribe(
            result => expect(result.status).toBeTruthy()
        );
        expect(httpClientSpy.post).toHaveBeenCalled();
    });

    it('should call caseIdsForBulkOperations', () => {
        const res: Array<Number> = [];
        httpClientSpy.post.mockReturnValue(of(res));
        const filter = [{ caseKeys: { operator: 0, value: '-486,-470' } }];
        const queryKey = 36;
        const queryContextKey = 2;

        service.caseIdsForBulkOperations$(filter, queryContextKey, queryKey, null);

        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });

    });
});
