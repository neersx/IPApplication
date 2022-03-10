import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { DisbursementDissectionService } from './disbursement-dissection.service';

describe('DisbursementDissectionService', () => {
    let http: HttpClientMock;
    let service: DisbursementDissectionService;

    beforeEach(() => {
        http = new HttpClientMock();
        service = new DisbursementDissectionService(http as any);
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('DisbursementDissectionService Services', () => {
        it('calls api to get wip base data and permissions', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getSupportData$();
            expect(http.get).toHaveBeenCalledWith('api/accounting/wip-disbursements/view-support');
        });

        it('call api to get wip default details', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.getDefaultWipItems$(123);
            expect(http.get).toHaveBeenCalledWith('api/accounting/wip-disbursements/wip-defaults/', {
                params: {
                    caseKey: '123'
                }
            });
        });

        it('calls api to validate date', () => {
            http.get = jest.fn().mockReturnValue(of({}));
            service.validateItemDate(new Date());
            expect(http.get).toHaveBeenCalledWith('api/accounting/wip-disbursements/validate', {
                params: {
                    itemDate: new Date().toString()
                }
            });
        });

        it('calls api to get default wip cost', () => {
            http.post = jest.fn().mockReturnValue(of({}));
            service.getDefaultWipCost$({});
            expect(http.post).toHaveBeenCalledWith('api/accounting/wip-disbursements/wip-costing/', {});
        });

        it('calls api to post submit data', () => {
            http.post = jest.fn().mockReturnValue(of({}));
            service.submitDisbursement({});
            expect(http.post).toHaveBeenCalledWith('api/accounting/wip-disbursements/', {});
        });

        describe('getDefaultNarrativeFromActivity', () => {
            it('calls the correct api if case is specified', () => {
                service.getDefaultNarrativeFromActivity('xyz', 1234);
                expect(http.get).toHaveBeenCalledWith('api/accounting/wip-disbursements/narrative', { params: { activityKey: 'xyz', caseKey: '1234', debtorKey: null, staffNameId: null } });
            });
            it('calls the correct api if only debtor is specified', () => {
                service.getDefaultNarrativeFromActivity('xyz', null, -101);
                expect(http.get).toHaveBeenCalledWith('api/accounting/wip-disbursements/narrative', { params: { activityKey: 'xyz', caseKey: null, debtorKey: '-101', staffNameId: null } });
            });
        });
    });
});
