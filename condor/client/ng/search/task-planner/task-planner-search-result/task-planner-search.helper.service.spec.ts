import { DateHelperMock } from 'mocks';
import { TaskPlannerServiceMock } from 'search/task-planner/task-planner.service.mock';
import { TabData } from '../task-planner.data';
import { TaskPlannerSearchHelperService } from './task-planner-search.helper.service';

describe('TaskPlannerSearchHelperService', () => {

    let service: TaskPlannerSearchHelperService;
    let taskPlannerService: TaskPlannerServiceMock;
    let dateHelperMock: DateHelperMock;

    beforeEach(() => {
        taskPlannerService = new TaskPlannerServiceMock();
        dateHelperMock = new DateHelperMock();
        service = new TaskPlannerSearchHelperService(taskPlannerService as any, dateHelperMock as any);
    });

    it('should create the service', () => {
        expect(service).toBeTruthy();
    });

    it('verify setSearchCriteria', () => {
        const tab: TabData = new TabData();
        const queryParam = { take: 10, skip: 0 };
        const activeQueryKey = 12;
        service.setSearchCriteria(tab, queryParam, activeQueryKey, false);
        expect(service.activeTab).toBe(tab);
        expect(service.queryParams).toBe(queryParam);
        expect(service.activeQueryKey).toEqual(activeQueryKey);
        expect(service.isSearchFromSearchBuilder).toBeFalsy();
    });

    it('verify getFilter', () => {
        const tab: TabData = {
            queryKey: 12,
            description: 'test',
            presentationId: 1,
            sequence: 1,
            canRevert: false,
            names: [{ key: 1 }, { key: 2 }],
            filter: { searchRequest: {} },
            savedSearch: {
                query: null,
                criteria: {
                    dateFilter: { useDueDate: 1, useReminderDate: 0, sinceLastWorkingDay: 3, from: new Date(), operator: '1' },
                    belongsTo: null,
                    hasNameGroup: null,
                    importanceLevel: null,
                    timePeriodId: null
                }
            }
        };
        const queryParam = { take: 10, skip: 0 };
        const activeQueryKey = 12;
        service.setSearchCriteria(tab, queryParam, activeQueryKey, false);
        const result = service.getFilter();
        expect(result.searchRequest.belongsTo.nameKeys.value).toEqual('1,2');
        expect(result.searchRequest.belongsTo.nameKey).toBeNull();
        expect(result.deselectedIds).toBeNull();
    });

    it('verify getFilter with none names', () => {
        const tab: TabData = {
            queryKey: 12,
            description: 'test',
            presentationId: 1,
            sequence: 1,
            canRevert: false,
            names: [],
            filter: { searchRequest: {} },
            savedSearch: {
                query: null,
                criteria: {
                    dateFilter: { useDueDate: 1, useReminderDate: 0, sinceLastWorkingDay: 3, from: new Date(), operator: '1' },
                    belongsTo: null,
                    hasNameGroup: null,
                    importanceLevel: null,
                    timePeriodId: null
                }
            }
        };
        const queryParam = { take: 10, skip: 0 };
        const activeQueryKey = 12;
        service.setSearchCriteria(tab, queryParam, activeQueryKey, false);
        const result = service.getFilter();
        expect(result.searchRequest.belongsTo.nameKeys).toBeNull();
    });

    it('verify getFilter with deSlectedRowKeys', () => {
        const tab: TabData = {
            queryKey: 12,
            description: 'test',
            presentationId: 1,
            sequence: 1,
            names: [{ key: 9 }, { key: 10 }],
            filter: { searchRequest: {} },
            canRevert: false,
            savedSearch: {
                query: null,
                criteria: {
                    dateFilter: { useDueDate: 1, useReminderDate: 0, sinceLastWorkingDay: 3, from: new Date(), operator: '1' },
                    belongsTo: null,
                    hasNameGroup: null,
                    importanceLevel: null,
                    timePeriodId: null
                }
            }
        };
        const deSelectedRowKeys = [1, 2];
        service.setSearchCriteria(tab, {}, 12, false);
        const result = service.getFilter(deSelectedRowKeys);
        expect(result.searchRequest.belongsTo.nameKeys.value).toEqual('9,10');
        expect(result.deselectedIds).toBe(deSelectedRowKeys);
    });

    it('verify getSearchRequestParams', () => {
        const tab: TabData = {
            queryKey: 12,
            description: 'test',
            presentationId: 1,
            sequence: 1,
            canRevert: false,
            names: [{ key: 1 }, { key: 2 }],
            filter: { searchRequest: {} },
            savedSearch: {
                query: null,
                criteria: {
                    dateFilter: { useDueDate: 1, useReminderDate: 0, sinceLastWorkingDay: 3, from: new Date(), operator: '1' },
                    belongsTo: null,
                    hasNameGroup: null,
                    importanceLevel: null,
                    timePeriodId: null
                }
            }
        };
        const queryParam = { take: 10, skip: 0 };
        service.setSearchCriteria(tab, queryParam, 12, false);
        const searchParams = service.getSearchRequestParams([]);
        expect(searchParams.queryKey).toEqual(12);
        expect(searchParams.params).toEqual(queryParam);
    });

});
