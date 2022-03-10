import { HttpClientMock } from 'mocks';
import { BillSearchService } from './bill-search.service';

describe('BillSearchService', () => {

    let service: BillSearchService;
    let httpClient: HttpClientMock;

    beforeEach(() => {
        httpClient = new HttpClientMock();
        service = new BillSearchService(httpClient as any);
    });

    it('should create the service', () => {
        expect(service).toBeTruthy();
    });

    it('Verify deleteDraftBill', () => {
        const itemEntityId = 12;
        const openItemNo = 'D152';
        service.deleteDraftBill(itemEntityId, openItemNo);
        expect(httpClient.delete).toHaveBeenCalledWith('api/accounting/billing/open-item/' + itemEntityId + '/' + openItemNo);
    });

});
