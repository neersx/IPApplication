import { HttpClientMock } from 'mocks';
import { CaseViewEventsService } from './events.service';

describe('case view events service', () => {
    let service: CaseViewEventsService;
    let http: HttpClientMock;

    beforeEach(() => {
        http = new HttpClientMock();

        service = new CaseViewEventsService(http as any);
    });

    it('returns events from server', () => {
        expect(service).toBeDefined();
        service.getCaseViewOccurredEvents(1, 5, { skip: 0 });
        expect(http.get).toHaveBeenCalledWith('api/case/1/caseviewevent/occurred', {
            params: {
                q: JSON.stringify({
                    importanceLevel: 5
                }),
                params: JSON.stringify({ skip: 0 })
            }
        });
    });

    it('returns due events from server', () => {
        expect(service).toBeDefined();
        service.getCaseViewDueEvents(1, 5, { skip: 0 });
        expect(http.get).toHaveBeenCalledWith('api/case/1/caseviewevent/due', {
            params: {
                q: JSON.stringify({
                    importanceLevel: 5
                }),
                params: JSON.stringify({ skip: 0 })
            }
        });
    });

    it('returns siteControlId from server', () => {
        expect(service).toBeDefined();
        service.siteControlId();
        expect(http.get).toHaveBeenCalledWith('api/case/eventNotesDetails/siteControlId');
    });
});