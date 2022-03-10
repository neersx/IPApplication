import { GridNavigationServiceMock, HttpClientMock } from 'mocks';
import { ActionEventsRequestModel } from './action-model';
import { CaseViewActionsService } from './case-view.actions.service';

describe('case view action service', () => {

    let service: CaseViewActionsService;
    let http = { get: jest.fn(), post: jest.fn() };
    let gridNavigationService: GridNavigationServiceMock;

    beforeEach(() => {
        http = {
            get: jest.fn().mockReturnValue({
                pipe: (args: any) => {
                    return [];
                }
            }), post: jest.fn()
        };
        gridNavigationService = new GridNavigationServiceMock();
        service = new CaseViewActionsService(http as any, gridNavigationService as any);
    });

    it('returns action data from server', () => {
        jest.spyOn(gridNavigationService, 'init');
        service.getActions$(1, 5, true, false, false, { skip: 0 });
        expect(http.get).toHaveBeenCalledWith('api/case/1/action', {
            params: {
                q: JSON.stringify({
                    importanceLevel: 5,
                    includeOpenActions: true,
                    includeClosedActions: false,
                    includePotentialActions: false
                }),
                params: JSON.stringify({ skip: 0 })
            }
        });
    });

    it('calls server to get view data', () => {
        service.getViewData$(1001);
        expect(http.get).toHaveBeenCalledWith('api/case/action/view/1001');
    });

    it('returns actions event data from server', () => {
        const criteria = {
            caseKey: 1,
            actionId: 'ac',
            cycle: 1,
            criteriaId: 1,
            importanceLevel: 5,
            isCyclic: false,
            AllEvents: false,
            MostRecent: false
        };
        const q: ActionEventsRequestModel = {
            criteria,
            params: { skip: 0 }
        };
        service.getActionEvents$(q);
        expect(gridNavigationService.setNavigationData).toHaveBeenCalled();
        expect(http.get).toHaveBeenCalledWith('api/case/1/action/ac', {
            params: {
                q: JSON.stringify({
                    cycle: 1,
                    criteriaId: 1,
                    importanceLevel: 5,
                    isCyclic: false
                }), params: JSON.stringify(q.params)
            }
        });
    });
});