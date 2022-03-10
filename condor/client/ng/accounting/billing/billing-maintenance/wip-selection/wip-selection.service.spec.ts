import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { WipSelectionService } from './wip-selection.service';

describe('WipSelectionService', () => {
    let http: HttpClientMock;
    let service: WipSelectionService;

    beforeEach(() => {
        http = new HttpClientMock();
        service = new WipSelectionService(http as any);
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });

    it('getAvailableWip - calls api to get available wip items', () => {
        http.get = jest.fn().mockReturnValue(of({}));
        const date = new Date();
        service.getAvailableWip(1, date, 1, [1], 1, 510);
        expect(http.post).toHaveBeenCalledWith('api/accounting/billing/wip-selection', {
            itemEntityId: 1,
            debtorId: 1,
            caseIds: [1],
            raisedByStaffId: 1,
            itemType: 510,
            itemDate: date
        });
    });

    it('getBillAvailableWip - calls api to get available wip items for existing bill', () => {
        http.get = jest.fn().mockReturnValue(of({}));
        const date = new Date();
        service.getBillAvailableWip(1, date, 510, 1);
        expect(http.post).toHaveBeenCalledWith('api/accounting/billing/wip-selection', {
            itemEntityId: 1,
            itemTransactionId: 1,
            itemType: 510,
            itemDate: date
        });
    });
});
