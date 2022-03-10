import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { AdjustWipService } from './adjust-wip.service';

describe('WipService', () => {
    let http: HttpClientMock;
    let service: AdjustWipService;

    beforeEach(() => {
        http = new HttpClientMock();
        service = new AdjustWipService(http as any);
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('Adjust Wip Services', () => {
        it('calls api to get wip base data and permissions', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getAdjustWipSupportData$();
            expect(http.get).toHaveBeenCalledWith('api/accounting/wip-adjustments/view-support');
        });

        it('call api to get adjust wip details', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getItemForWipAdjustment$(123, 1, 1);
            expect(http.get).toHaveBeenCalledWith('api/accounting/wip-adjustments/adjust-item', {
                params: {
                    entityKey: '123',
                    transKey: '1',
                    wipSeqKey: '1'
                }
            });
        });
    });
    it('calls the correct API passing the parameters', () => {
        const data: any = {
            entity: {
                requestedByStaff: { key: 1 },
                wipCode: 'AB',
                reason: null,
                transactionDate: new Date(),
                originalTransDate: null,
                localValue: 56,
                localAdjustment: null,
                currentLocalValue: 1000,
                foreignValue: null,
                foreignAdjustment: null,
                currentForeignValue: 1000,
                AdjustWipItem: {
                    OriginalWIPItem: {
                        LocalCurrency: 10,
                        ForeignCurrency: 20
                    }
                }
            }
        };
        service.submitAdjustWip(data);
        expect(http.post).toHaveBeenCalledWith('api/accounting/wip-adjustments/adjust-item', data);
    });
});
