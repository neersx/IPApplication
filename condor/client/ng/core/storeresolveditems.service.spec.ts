import { HttpClientMock } from 'mocks';
import { StoreResolvedItemsService } from './storeresolveditems.service';

describe('StoreResolvedItems Service', () => {
    let storeResolvedItemsService;

    beforeEach(() => {
        const httpMock = new HttpClientMock();
        storeResolvedItemsService = new StoreResolvedItemsService(httpMock as any);
    });

    it('should create', () => {
        expect(storeResolvedItemsService).toBeTruthy();
    });

    it('should have called  create', () => {
        storeResolvedItemsService.add('');
        expect(storeResolvedItemsService.http.post).toHaveBeenCalled();
    });

});
