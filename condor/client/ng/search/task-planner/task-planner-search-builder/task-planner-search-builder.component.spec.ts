import { IpxNotificationServiceMock, NotificationServiceMock, SearchPresentationServiceMock, StateServiceMock } from 'mocks';
import { KeyBoardShortCutServiceMock } from 'mocks/keyboardshortcutservice.mock';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { TaskPlannerServiceMock } from '../task-planner.service.mock';
import { DateFilterType } from './search-builder.data';
import { TaskPlannerSearchBuilderComponent } from './task-planner-search-builder.component';

describe('TaskPlannerSearchBuilderComponent', () => {
    let component: TaskPlannerSearchBuilderComponent;
    let stateService: StateServiceMock;
    let taskPlannerService: TaskPlannerServiceMock;
    let keyBoardShortCutService: KeyBoardShortCutServiceMock;
    const prevState = { name: 'taskPlanner', params: {} };
    let transition: any;
    let searchRequest: any;
    let formData: any;
    const ipxNotificationService = new IpxNotificationServiceMock();
    const notificationServiceMock = new NotificationServiceMock();
    const modalService = new ModalServiceMock();
    beforeEach(() => {
        transition = { from: jest.fn().mockReturnValue(prevState) };
        stateService = new StateServiceMock();
        keyBoardShortCutService = new KeyBoardShortCutServiceMock();
        taskPlannerService = new TaskPlannerServiceMock();

        const searchPresentationService = new SearchPresentationServiceMock();
        component = new TaskPlannerSearchBuilderComponent(stateService as any, keyBoardShortCutService as any, taskPlannerService as any, transition,
            notificationServiceMock as any, modalService as any, searchPresentationService as any, ipxNotificationService as any);
        component.viewData = { importanceLevels: [], formData: {}, numberTypes: [], nameTypes: [], showCeasedNames: true, queryKey: null };
        searchRequest = {
            include: {
                isReminders: 1,
                isDueDates: 0,
                isAdHocDates: 1
            }, officeKeys: { operator: '0', value: '11,23' }
        };
        formData = {
            general: {
                belongingToFilter: { value: '', actingAs: {} },
                includeFilter: {},
                searchByFilter: {},
                dateFilter: {
                    operator: '7',
                    dateFilterType: DateFilterType.period,
                    datePeriod: { periodType: 'W', from: 1, to: 3 }
                },
                importanceLevel: {}
            },
            cases: {
                caseFamily: { operator: '0', value: { key: 12, code: 'AA', value: 'Test' } }
            }
        };
        component.topicOptions = {
            topics: [
                {
                    clear: jest.fn(),
                    isValid: jest.fn().mockReturnValue(true),
                    getFormData: jest.fn().mockReturnValue({
                        searchRequest,
                        formData
                    })
                }]
        } as any;
        component.savedTaskPlannerData = {
            queryKey: -31, queryName: 'saved', formData: [{
                topicKey: 'general',
                formData: {
                    belongingToFilter: {
                        names: null,
                        nameGroups: null,
                        actingAs: {
                            isDueDate: true,
                            isReminder: true,
                            nameTypes: null
                        },
                        value: 'myself'
                    }
                }
            }]
        };
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        prevState.name = '';
        component.previousStateParams = { name: 'taskPlanner', params: taskPlannerService.previousStateParam };
        component.ngOnInit();
        expect(component.topicOptions).toBeDefined();
        expect(component.topicOptions.topics[0].key).toEqual('general');
        expect(component.topicOptions.topics[1].key).toEqual('casesCriteria');
        expect(component.hasPreviousState).toEqual(true);
        expect(component.queryKey).toEqual(-31);
        expect(component.activeTabTitle).toEqual('saved');
    });

    it('validate ngOnInit with previousStateParams', () => {
        component.previousStateParams = { name: 'taskPlanner', params: taskPlannerService.previousStateParam };
        prevState.name = 'taskPlanner';
        component.ngOnInit();
        expect(component.formData).toBe(taskPlannerService.previousStateParam.formData);
        expect(component.hasPreviousState).toBeTruthy();
        expect(component.topicOptions).toBeDefined();
    });

    it('validate savedTaskplannerSearch', () => {
        component.previousStateParams = { name: 'taskPlanner', params: taskPlannerService.previousStateParam };
        prevState.name = 'taskPlanner';
        component.ngOnInit();
        expect(component.formData).toBe(taskPlannerService.previousStateParam.formData);
        expect(component.hasPreviousState).toBeTruthy();
        expect(component.topicOptions.topics.length).toEqual(5);
        expect(component.viewData.formData.general).toBeDefined();
    });

    it('buildFormData', () => {
        const form = component.buildFormData();
        expect(form).toBeDefined();
        expect(form.general).toBeDefined();
    });

    it('validate clear when no saved task planner is there', () => {
        component.clear();
        expect(component.topicOptions).toBeDefined();
        const generalTopic = component.topicOptions.topics[0] as any;
        expect(generalTopic.clear).toHaveBeenCalled();
    });

    it('validate canSearch', () => {
        const result = component.canSearch();
        expect(result).toBeTruthy();
    });

    it('validate search', () => {
        component.queryKey = -31;
        component.activeTabTitle = 'Search1';
        component.search();
        expect(stateService.go).toHaveBeenCalledWith('taskPlanner', {
            filterCriteria: { searchRequest }, formData, searchBuilder: true,
            selectedColumns: null, isFormDirty: false, queryKey: -31, searchName: 'Search1'
        });
    });

    it('validate openPresentation', () => {
        component.openPresentation();
        expect(stateService.go).toHaveBeenCalledWith('searchpresentation', { filter: { filterCriteria: { searchRequest }, formData }, queryKey: null, isPublic: false, queryName: undefined, queryContextKey: queryContextKeyEnum.taskPlannerSearch });
    });

    it('validate openSaveSearch', () => {
        component.openSaveSearch({}, [], false, 0);
        expect(modalService.openModal).toHaveBeenCalled();
    });
    it('validate updateTaskPlannerSearch when query key is given', () => {
        component.queryKey = -31;
        component.updateTaskPlannerSearch({}, [], false, 0);
        expect(taskPlannerService.updateTaskPlannerSearch).toHaveBeenCalled();
    });

    it('validate updateTaskPlannerSearch when query key is not given', () => {
        component.queryKey = null;
        component.updateTaskPlannerSearch({}, [], false, 0);
        expect(taskPlannerService.updateTaskPlannerSearch).not.toHaveBeenCalled();
    });

    it('validate editTaskPlannerSavedSearch', () => {
        component.queryKey = -31;
        component.editTaskPlannerSavedSearch();
        expect(modalService.openModal).toHaveBeenCalled();
    });

    it('validate disableEditTaskplanner SaveSearch for public search', () => {
        component.queryKey = 31;
        component.isPublic = true;
        const result = component.disableEditTaskplannerSaveSearch();
        expect(result).toEqual(false);
    });

    it('validate disableEditTaskplanner SaveSearch for private search', () => {
        component.queryKey = 31;
        component.isPublic = false;
        const result = component.disableEditTaskplannerSaveSearch();
        expect(result).toEqual(false);
    });

    it('validate disableEditTaskplanner SaveSearch for private search if dont have update permission', () => {
        component.queryKey = 31;
        component.isPublic = true;
        taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.update = false;
        const result = component.disableEditTaskplannerSaveSearch();
        expect(result).toEqual(true);
    });

    it('Should call deleteSavedSearch', () => {
        component.deleteSavedSearch();
        expect(notificationServiceMock.confirmDelete).toHaveBeenCalled();
    });

    it('Should call disableDeleteSaveSearch when query key is not there', () => {
        const result = component.disableDeleteSaveSearch();
        expect(result).toEqual(true);
    });

    it('Should call disableDeleteSaveSearch when query key is there and come from taskplanner', () => {
        component.queryKey = 31;
        const result = component.disableDeleteSaveSearch();
        expect(result).toEqual(false);
    });

});
