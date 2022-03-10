import { HttpClientMock } from 'mocks';
import { SearchTypeMenuProviderService } from './search-type-menu-provider.service';

describe('SearchTypeMenuProviderService', () => {

    let service: SearchTypeMenuProviderService;
    const httpMock = new HttpClientMock();

    beforeEach(() => {
        service = new SearchTypeMenuProviderService(httpMock as any);
    });

    it('should load task serach type menu service', () => {
        expect(service).toBeTruthy();
    });

    it('validate getAdditionalViewDataFromFilterCriteria', () => {
        const filterRequest = {
            searchRequestParams: {
                queryKey: 1,
                criteria: {},
                params: {},
                queryContext: 11,
                selectedColumns: null,
                presentationType: null
            }
        };
        service.getAdditionalViewDataFromFilterCriteria(filterRequest);
        expect(httpMock.post).toHaveBeenCalledWith(service.baseApiRoute + 'additionalviewdata', filterRequest);
    });
});