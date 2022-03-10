import { HttpClientMock } from 'mocks';
import { AffectedCasesSetAgentService } from './affected-cases-set-agent.service';

describe('Service: affected cases', () => {
    let http: HttpClientMock;
    let service: AffectedCasesSetAgentService;
    beforeEach(() => {
        http = new HttpClientMock();
        service = new AffectedCasesSetAgentService(http as any);
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });
    it('should call save api for setAgent', () => {
        const agentId = 1;
        const isCaseNameSet = true;
        const rows = ['1', '2'];
        const mainCaseId = 1;
        service.setAgent(agentId, mainCaseId, isCaseNameSet, rows);
        expect(http.post).toHaveBeenCalledWith('api/case/affectedCases/setAgent', {
            agentId,
            mainCaseId,
            isCaseNameSet,
            affectedCases: rows
        });
    });
    it('should call get for the getCaseReference', () => {
        service.getCaseReference(1);
        expect(http.get).toHaveBeenCalledWith(`api/case/getCaseRefAndNameType/${1}`);
    });
});
