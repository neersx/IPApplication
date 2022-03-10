import { TypeOfDetails } from 'accounting/billing/billing.model';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { CaseDebtorService } from './case-debtor.service';

describe('CaseDebtorService', () => {
    let http: HttpClientMock;
    let service: CaseDebtorService;

    beforeEach(() => {
        http = new HttpClientMock();
        service = new CaseDebtorService(http as any);
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('CaseDebtorService Services', () => {
        it('calls api to get openItem Cases', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getOpenItemCases(1, 12);
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/open-item/cases', {
                params: {
                    itemEntityId: '1',
                    itemTransactionId: '12'
                }
            });
        });

        it('call api to get cases and casesList', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            const request = {
                caseIds: '123',
                raisedByStaffId: 12
            };
            service.getCases(request);
            expect(http.post).toHaveBeenCalledWith('api/accounting/billing/cases/', request);
        });

        it('calls api to validate date', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getCaseDebtors(123);
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/cases/case-debtors', {
                params: {
                    caseId: '123'
                }
            });
        });

        it('calls api to get Debtors list for case', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getDebtors(TypeOfDetails.Summary, 123, null, null, 'RN', 3202, 6, 12, false, false, null);
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/debtors/', {
                params: {
                    type: 'Summary',
                    caseId: '123',
                    debtorNameId: JSON.stringify(12),
                    entityId: '3202',
                    action: 'RN',
                    raisedByStaffId: JSON.stringify(6),
                    useSendBillsTo: JSON.stringify(false),
                    useRenewalDebtor: JSON.stringify(false),
                    billDate: JSON.stringify(null)
                }
            });
        });

        it('calls api to get Debtors list for caseList', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getDebtors(TypeOfDetails.Details, null, 959, null, 'RN', 3202, null, null, false, false, null);
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/debtors/', {
                params: {
                    type: 'Detailed',
                    caseId: JSON.stringify(null),
                    debtorNameId: 'null',
                    entityId: '3202',
                    action: 'RN',
                    raisedByStaffId: 'null',
                    useSendBillsTo: 'false',
                    caseListId: JSON.stringify(959),
                    useRenewalDebtor: JSON.stringify(false),
                    billDate: JSON.stringify(null)
                }
            });
        });

        it('calls api to get Open Item debtors', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getOpenItemDebtors(123, 345, false);
            expect(http.get).toHaveBeenCalledWith('api/accounting/billing/open-item/debtors/', {
                params: {
                    entityId: JSON.stringify(123),
                    transactionId: JSON.stringify(345),
                    raisedByStaffId: JSON.stringify(false)
                }
            });
        });

        it('calls api to get getChangedDebtors', () => {
            http.post = jest.fn().mockReturnValue(of({}));
            const request = {
                caseId: 123,
                entityId: -2097,
                action: 'RN',
                useRenewalDebtor: true,
                billDate: ''
            };
            service.getChangedDebtors({}, request);
            expect(http.post).toHaveBeenCalledWith('api/accounting/billing/debtors/', {}, {
                params: {
                    caseId: JSON.stringify(request.caseId),
                    entityId: JSON.stringify(request.entityId),
                    action: request.action,
                    billDate: request.billDate,
                    useRenewalDebtor: JSON.stringify(request.useRenewalDebtor)
                }
            });
        });
    });
});
