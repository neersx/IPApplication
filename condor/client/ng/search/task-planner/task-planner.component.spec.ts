import { services } from '@uirouter/core';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, TaskPlannerPersistenceServiceMock, TranslateServiceMock } from 'mocks';
import { RightBarNavServiceMock } from 'rightbarnav/rightbarnavservice.mock';
import { TaskPlannerSearchResultComponent } from './task-planner-search-result/task-planner-search-result.component';
import { TaskPlannerComponent } from './task-planner.component';
import { QueryData } from './task-planner.data';
import { TaskPlannerServiceMock } from './task-planner.service.mock';

describe('TaskPlannerComponent', () => {
    let component: TaskPlannerComponent;
    let cdr: ChangeDetectorRefMock;
    let taskPlannerService: TaskPlannerServiceMock;
    let persistenceServie: TaskPlannerPersistenceServiceMock;
    const trans = {
        params: jest.fn()
    };
    let tab1: QueryData;
    let tab2: QueryData;
    const translateServiceMock = new TranslateServiceMock();
    const rightBarNavService = new RightBarNavServiceMock();
    const appContext = new AppContextServiceMock();
    const commonService = new CommonUtilityServiceMock();
    const localSettings = new LocalSettingsMock();
    const ipxNotificationService = new IpxNotificationServiceMock();
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        persistenceServie = new TaskPlannerPersistenceServiceMock();
        taskPlannerService = new TaskPlannerServiceMock();
        component = new TaskPlannerComponent(cdr as any, persistenceServie as any, taskPlannerService as any, rightBarNavService as any, appContext as any, localSettings as any, ipxNotificationService as any);
        component.searchResult = new TaskPlannerSearchResultComponent({} as any, cdr as any, {} as any, {} as any,
            {} as any, {} as any, persistenceServie as any, {} as any, translateServiceMock as any, {} as any, {} as any, {} as any, {} as any,
            {} as any, {} as any, {} as any, {} as any, new AppContextServiceMock() as any, {} as any, {} as any, {} as any, commonService as any, {} as any, {} as any, {} as any, null);
        component.viewData = {
            q: '',
            permissions: {},
            isExternal: false,
            filter: '',
            queryContext: 970,
            criteria: null,
            timePeriods: [],
            maintainEventNotes: false,
            reminderDeleteButton: 0,
            maintainTaskPlannerSearch: false,
            maintainTaskPlannerSearchPermission: { update: false, insert: true },
            query: { description: 'My Tasks', key: -27, presentationId: 123, searchName: 'My Tasks', tabSequence: 1 },
            exportLimit: 10,
            autoRefreshGrid: true,
            canViewAttachments: true,
            canAddCaseAttachments: true,
            provideDueDateInstructions: null,
            showLinksForInprotechWeb: false
        };
        tab1 = { description: 'My Tasks Tab 1', key: -27, presentationId: 123, searchName: 'Tab 1', tabSequence: 1 };
        tab2 = { description: 'My Tasks Tab 2', key: -27, presentationId: 123, searchName: 'Tab 2', tabSequence: 2 };
        persistenceServie.tabs = [tab1, tab2];
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        spyOn(component.searchResult, 'initializeTab');
        jest.spyOn(persistenceServie, 'clear');
        jest.spyOn(persistenceServie.changedTabSeq$, 'subscribe');
        component.ngOnInit();
        const tab: any = {
            description: 'My Tasks',
            key: -27,
            presentationId: 123,
            searchName: 'My Tasks',
            tabSequence: 1
        };
        expect(component.tabs.length).toEqual(1);
        expect(component.selectedTab).toEqual(tab);
        expect(component.selectedSavedSearch[0].searchName).toEqual('My Tasks');
        expect(component.selectedSavedSearch[0].key).toEqual(-27);
    });

    it('validate selectTab', () => {
        spyOn(component.searchResult, 'initializeTab');
        component.tabs = [tab1, tab2];
        component.selectedSavedSearch = component.tabs;
        component.selectTab(tab2);
        expect(component.selectedTab).toEqual(tab2);
    });

    it('validate selectTab with unsaved notes', () => {
        spyOn(component.searchResult, 'initializeTab');
        component.tabs = [tab1, tab2];
        component.selectedSavedSearch = component.tabs;
        component.searchResult.dirtyNotesAndComments.set('C^45C', true);
        component.selectedTab = tab1;
        component.selectTab(tab2);
        expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalledWith('modal.discardchanges.title', 'taskPlanner.discardMessage', 'modal.discardchanges.discardButton', 'modal.discardchanges.cancel');
        expect(ipxNotificationService.modalRef.content.confirmed$.subscribe).toHaveBeenCalled();
        expect(component.selectedTab).toEqual(tab1);
    });

    it('validate onChangeQueryKey', () => {
        spyOn(component.searchResult, 'onSavedSearchChange');
        component.selectedSavedSearch = [tab1];
        component.onChangeQueryKey(tab1, tab1.tabSequence);
        expect(component.searchResult.onSavedSearchChange).toHaveBeenCalled();
    });

    it('validate trackBy', () => {
        spyOn(component.searchResult, 'initializeTab');
        const result = component.trackBy(2, {});
        expect(result).toEqual(2);
    });

    it('validate setStoreOnToggle', () => {
        spyOn(component.searchResult, 'togglePreview');
        component.setStoreOnToggle(true as any);
        expect(localSettings.keys.taskPlanner.showPreview.setLocal).toHaveBeenCalledWith(true);
        expect(component.searchResult.togglePreview).toHaveBeenCalledWith(true);
        expect(cdr.markForCheck).toHaveBeenCalled();
    });

});
