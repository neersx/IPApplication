import { HttpClientMock } from 'mocks';
import { ChecklistSearchService } from './checklist-search.service';

describe('Service: ScreenDesigner', () => {
    let service: ChecklistSearchService;
    let httpMock: HttpClientMock;

    beforeEach(() => {
        httpMock = new HttpClientMock();
        service = new ChecklistSearchService(httpMock as any);
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });

    describe('getCriteriaSearchViewData$', () => {
        it('should call the correct api to get the view data', () => {
            service.getCriteriaSearchViewData$();
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/checklist-configuration/view');
        });
    });

    describe('getCaseCriterias', () => {
        it('should build the criteria and call the correct api', () => {
            const searchCriteria = {
                caseType: {code: 'ABC'},
                caseCategory: {code: '777'},
                checklist: {key: 555},
                profile: {key: '123'},
                jurisdiction: {code: 'YBXA'},
                propertyType: {code: 'PTA'},
                subType: {code: 'ST'},
                basis: {code: 'BS'},
                office: {key: '9001'},
                applyTo: 'local',
                includeProtectedCriteria: true,
                matchType: 'exact-match'
            };
            service.getCaseCriterias$('exact-match', searchCriteria, {});
            expect(httpMock.get.mock.calls[0][0]).toBe('api/configuration/rules/checklist-configuration/search');
            expect(httpMock.get.mock.calls[0][1].params.criteria).toEqual(JSON.stringify({
                caseType: 'ABC',
                caseCategory: '777',
                profile: '123',
                jurisdiction: 'YBXA',
                propertyType: 'PTA',
                subType: 'ST',
                basis: 'BS',
                office: '9001',
                checklist: 555,
                applyTo: 'local',
                includeProtectedCriteria: true,
                matchType: 'exact-match'
            }));
        });
    });

    describe('search$', () => {
        it('should call criteria by ids search when match type is criteria', () => {
            service.getChecklistCriteriasByIds$ = jest.fn();
            service.search$('criteria', {p: 111}, {e: 222});
            expect(service.getChecklistCriteriasByIds$).toBeCalledWith({p: 111}, {e: 222});
        });
        it('should call criteria by case search when match type is not criteria', () => {
            service.getCaseCriterias$ = jest.fn();
            service.search$('notCriteria', {p: 111}, {e: 222});
            expect(service.getCaseCriterias$).toBeCalledWith('notCriteria', {p: 111}, {e: 222});
        });
    });

    describe('getChecklistCriteriasByIds$', () => {
        it('should call the api correctly', () => {
            service.getChecklistCriteriasByIds$({
                criteria: [{
                    id: 123,
                    stuff: 'test1'
                }, {
                    id: 2,
                    stuff: 'test2'
                }, {
                    id: 3455,
                    stuff: 'test3'
                }, {
                    id: 222111,
                    stuff: 'test4'
                }]
            }, {
                params: {}
            });
            expect(httpMock.get.mock.calls[0][0]).toBe('api/configuration/rules/checklist-configuration/searchByIds');
            expect(httpMock.get.mock.calls[0][1].params.ids).toEqual(JSON.stringify([123, 2, 3455, 222111]));
        });
    });
});