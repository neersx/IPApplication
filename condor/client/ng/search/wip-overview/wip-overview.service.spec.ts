import { HttpClientMock } from 'mocks';
import { WipOverviewService } from './wip-overview.service';

describe('WipOverviewService', () => {

    let service: WipOverviewService;
    let httpClient: HttpClientMock;

    beforeEach(() => {
        httpClient = new HttpClientMock();
        service = new WipOverviewService(httpClient as any, {} as any);
    });

    it('should create the service', () => {
        expect(service).toBeTruthy();
    });

    it('verify validateSingleBillCreation', () => {
        const selectedRows = [{ key: 12, caseRef: '1234/a' }, { key: 22, caseRef: '1234/b' }];
        service.validateSingleBillCreation(selectedRows);
        expect(httpClient.post).toHaveBeenCalledWith('api/search/wipoverview/validateSingleBillCreation', selectedRows);
    });

    it('verify isEntityRestrictedByCurrency', () => {
        service.isEntityRestrictedByCurrency(12);
        expect(httpClient.get).toHaveBeenCalledWith('api/search/wipoverview/isEntityRestrictedByCurrency/12');
    });

});
