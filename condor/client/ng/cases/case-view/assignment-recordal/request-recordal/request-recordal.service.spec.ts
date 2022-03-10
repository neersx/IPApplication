import { HttpClientMock } from 'mocks';
import { RecordalRequest, RecordalRequestType } from '../affected-cases.model';
import { RequestRecordalService } from './request-recordal.service';

describe('Service: recordal request cases', () => {
    let http: HttpClientMock;
    let service: RequestRecordalService;
    beforeEach(() => {
        http = new HttpClientMock();
        service = new RequestRecordalService(http as any);
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });

    it('should call getCaseReference', () => {
        service.getCaseReference(123);
        expect(http.get).toHaveBeenCalledWith(`api/case/getCaseReference/${123}`);
    });

    it('should call get for the request recordals cases API', () => {
        const req: RecordalRequest = { caseId: 123, selectedRowKeys: ['123'], deSelectedRowKeys: [], isAllSelected: false, requestType: RecordalRequestType.Request };
        service.getRequestRecordal(req);
        expect(http.post).toHaveBeenCalledWith('api/case/requestRecordal', req);
    });

    it('should call get for the saveRecordal API', () => {
        const request: any = { caseId: 123, seqIds: [1], requestedDate: new Date(), requestType: RecordalRequestType.Request };
        service.onSaveRecordal(request.caseId, request.seqIds, request.requestedDate, request.requestType);
        expect(http.post).toHaveBeenCalledWith('api/case/saveRecordal', {
            caseId: 123, seqIds: request.seqIds, requestedDate:  request.requestedDate, requestType: RecordalRequestType.Request
        });
    });
});