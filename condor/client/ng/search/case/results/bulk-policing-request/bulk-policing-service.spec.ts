import { of } from 'rxjs';
import { BulkUpdateReasonData } from 'search/case/bulk-update/bulk-update.data';
import { BulkPolicingService, BulkPolicingViewData } from './bulk-policing-service';

describe('BulkPolicingService', () => {
    let service: BulkPolicingService;
    let httpClientSpy;
    beforeEach(() => {
        httpClientSpy = { get: jest.fn(), post: jest.fn() };
        service = new BulkPolicingService(httpClientSpy);
    });
    it('should exist', () => {
        expect(service).toBeDefined();
    });
    it('should call getBulkPolicingViewData', () => {
        const response: BulkPolicingViewData = new BulkPolicingViewData();
        httpClientSpy.get.mockReturnValue(of(response));
        service.getBulkPolicingViewData().subscribe(
            result => expect(result).toEqual(response)
        );
    });
    it('should call sendBulkPolicingRequest', () => {
        const params = {
            selectedCases: [1, 2],
            caseAction: 'AS',
            reasonData: new BulkUpdateReasonData()
        };
        httpClientSpy.post.mockReturnValue(of({}));
        service.sendBulkPolicingRequest(params.selectedCases, params.caseAction, params.reasonData);
        spyOn(httpClientSpy, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    });
});