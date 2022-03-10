import { HttpClientMock } from 'mocks';
import { CaseBillNarrativeService } from './case-bill-narrative.service';

describe('CaseBillNarrativeService', () => {
    let http: HttpClientMock;
    let service: CaseBillNarrativeService;
    beforeEach(() => {
        http = new HttpClientMock();
        service = new CaseBillNarrativeService(http as any);
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });
    it('should call save api for setCaseBillNarrative', () => {
        const data = {
            caseKey: 1,
            language: 1,
            notes: 'text'
        };
        service.setCaseBillNarrative(data);
        expect(http.post).toHaveBeenCalledWith('api/accounting/setCaseBillNarrative', data);
    });
    it('should call get for the getCaseReference', () => {
        service.getCaseNarativeDefaults(1);
        expect(http.get).toHaveBeenCalledWith(`api/accounting/getCaseBillNarrativeDefaults/${1}`);
    });
    it('should call get api for getCaseBillNarratives', () => {
        const data = {
            caseKey: 1,
            language: 1
        };
        service.getAllCaseNarratives(1);
        expect(http.get).toHaveBeenCalledWith('api/accounting/getAllCaseBillNarratives/1');
    });

    it('should call post api for deleteCaseBillNarrative', () => {
        const data = {
            caseKey: 1,
            language: 1
        };
        service.deleteCaseBillNarrative(data);
        expect(http.post).toHaveBeenCalledWith('api/accounting/deleteCaseBillNarrative', data);
    });
});
