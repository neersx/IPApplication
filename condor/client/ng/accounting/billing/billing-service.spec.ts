import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { BillingService } from './billing-service';

describe('BillingService', () => {
    let http: HttpClientMock;
    let service: BillingService;

    beforeEach(() => {
        http = new HttpClientMock();
        service = new BillingService(http as any);
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('Billing Services', () => {
        it('calls api to get wip base settings', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getSettings$();
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/settings?scope=site,user');
        });

        it('call api to get open item details fpr new debit note', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getOpenItem$(510, null, null);
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/open-item?itemType=510');
        });
        it('call api to get open item details fpr existing debit note', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getOpenItem$(null, 1, '1');
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/open-item?itemEntityId=1&openItemNo=1');
        });

        it('calls api to get billing settings', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getBillSettings$(123, 34, 99, 'AA');
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/settings', {
                params: {
                    scope: 'bill',
                    debtorId: '123',
                    caseId: '34',
                    entityId: '99',
                    action: 'AA'
                }
            });
        });
    });

    describe('Valid Action', () => {
        it('should call valid-action api', () => {
            http.post = jest.fn().mockReturnValueOnce(of({ key: 'RN', value: 'Renewal', code: 'RN' }));
            const row = { CaseTypeCode: 'A', CountryCode: 'AU', PropertyType: 'P', OpenAction: 'RN' };
            service.setValidAction(row);
            expect(http.post).toHaveBeenCalledWith('api/accounting/billing/valid-action', {
                caseTypeCode: row.CaseTypeCode,
                countryCode: row.CountryCode,
                propertyTypeCode: row.PropertyType,
                actionCode: row.OpenAction
            });
        });
        it('should call validAction clear on clear function', () => {
            service.currentAction$.next = jest.fn();
            service.clearValidAction();
            expect(service.currentAction$.next).toBeCalledWith(null);
        });
    });
});
