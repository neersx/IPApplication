import { GridNavigationServiceMock, HttpClientMock } from 'mocks';
import { CaseViewActionsServiceMock } from '../actions/case-view.actions.service.mock';
import { EventRuleDetailsService } from './event-rule-details.service';

describe('event rule details service', () => {

    let service: EventRuleDetailsService;
    let http;
    let actionServiceMock: CaseViewActionsServiceMock;
    const gridNavigationService: GridNavigationServiceMock = new GridNavigationServiceMock();

    beforeEach(() => {
        http = new HttpClientMock();
        actionServiceMock = new CaseViewActionsServiceMock();
        service = new EventRuleDetailsService(http, actionServiceMock as any, gridNavigationService as any);
    });

    it('calls server to get event rule details', () => {
        const request = {
            caseId: 123,
            eventNo: 12,
            cycle: 1,
            action: 'CA'
        };
        service.getEventDetails$(request);
        expect(http.get).toHaveBeenCalledWith('api/case/eventRules/getEventRulesDetails', {
            params: {
                q: JSON.stringify(
                    {
                        caseId: 123,
                        eventNo: 12,
                        cycle: 1,
                        action: 'CA'
                    })
            }
        });
    });
});