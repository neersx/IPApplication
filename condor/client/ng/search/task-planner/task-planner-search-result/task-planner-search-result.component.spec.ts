import { fakeAsync, flush, tick } from '@angular/core/testing';
import { NgForm } from '@angular/forms';
import { AttachmentModalServiceMock } from 'common/attachments/attachment-modal.service.mock';
import { AttachmentPopupServiceMock } from 'common/attachments/attachments-popup/attachment-popup.service.mock';
import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, FileDownloadService, IpxGridOptionsMock, IpxNotificationServiceMock, MessageBroker, NgZoneMock, NotificationServiceMock, SearchExportServiceMock, StateServiceMock, TaskPlannerPersistenceServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { ReportExportFormat } from 'search/results/report-export.format';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { Criteria, DateRange, QueryData } from '../task-planner.data';
import { TaskPlannerServiceMock } from '../task-planner.service.mock';
import { TaskPlannerSearchResultComponent } from './task-planner-search-result.component';

describe('TaskPlannerSearchResultComponent', () => {
    let component: TaskPlannerSearchResultComponent;
    let localSettings: LocalSettingsMock;
    let cdr: ChangeDetectorRefMock;
    let taskPlannerService: TaskPlannerServiceMock;
    let dateHelper: any;
    let stateService: StateServiceMock;
    let caseHelper: any;
    let persistenceService: TaskPlannerPersistenceServiceMock;
    let tab: any;
    let attachmentModalService: AttachmentModalServiceMock;
    let attachmentPopupService: AttachmentPopupServiceMock;
    const searchTypeActionMenuProvider = {
        getConfigurationActionMenuItems: jest.fn().mockReturnValue([]),
        initializeContext: jest.fn()
    };
    const taskPlannerSerachResultFilterService = {
        getFilter: jest.fn().mockReturnValue({ exportFilter: {} })
    };
    const translateServiceMock = new TranslateServiceMock();
    let messageBroker: any;
    const notificationServiceMock = new NotificationServiceMock();
    const zone = new NgZoneMock();
    const searchExportServiceMock = new SearchExportServiceMock();
    const commonServiceMock = new CommonUtilityServiceMock();
    const fileDownloadService = new FileDownloadService();
    let exportFormat: ReportExportFormat;
    let localDatePipe: any;
    const taskMenuProvider = {
        subscribeCaseWebLinks: jest.fn().mockReturnValue([]),
        _baseTasks: jest.fn().mockReturnValue([]),
        initializeContext: jest.fn(),
        isMaintainEventFireTaskMenu$: {
            subscribe: jest.fn()
        },
        isMaintainEventFireTaskMenuWhenGrouping$: { subscribe: jest.fn(), next: jest.fn() },
        queryContextKey: 970, getConfigurationTaskMenuItems: jest.fn().mockReturnValue([
            {
                id: 'RecordTime',
                text: 'caseTaskMenu.recordTime',
                icon: 'cpa-icon cpa-icon-clock-o',
                action: jest.fn().mockReturnValue(10)
            },
            {
                id: 'RecordTimeWithTimer',
                text: 'caseTaskMenu.recordTimer',
                icon: 'cpa-icon cpa-icon-clock-timer',
                action: jest.fn().mockReturnValue(10)
            },
            {
                id: 'caseWebLinks',
                text: 'caseTaskMenu.openCaseWebLinks',
                icon: 'cpa-icon cpa-icon-bookmark',
                action: jest.fn().mockReturnValue(10)
            }
        ])
    };
    const modalService = new ModalServiceMock();
    const ipxNotificationService = new IpxNotificationServiceMock();
    const searchHelperService = {};
    const reminderActionProvier = {};
    const adhocDateService = { viewData: jest.fn().mockReturnValue(new Observable()) };
    const searchPersistenceServiceMock = {
        getSearchPresentationData: jest.fn(),
        setSearchPresentationData: jest.fn()
    };
    beforeEach(() => {
        localSettings = new LocalSettingsMock();
        cdr = new ChangeDetectorRefMock();
        taskPlannerService = new TaskPlannerServiceMock();
        dateHelper = { toLocal: jest.fn().mockReturnValue('01-10-2020') };
        stateService = new StateServiceMock();
        caseHelper = {};
        persistenceService = new TaskPlannerPersistenceServiceMock();
        messageBroker = new MessageBroker();
        attachmentModalService = new AttachmentModalServiceMock() as any;
        attachmentPopupService = new AttachmentPopupServiceMock();
        localDatePipe = { transform: jest.fn(d => '20-Sep-2021') };
        component = new TaskPlannerSearchResultComponent(localSettings as any,
            cdr as any,
            taskPlannerService as any,
            dateHelper,
            stateService as any,
            caseHelper,
            persistenceService as any,
            taskPlannerSerachResultFilterService as any,
            translateServiceMock as any,
            messageBroker,
            notificationServiceMock as any,
            zone as any,
            searchExportServiceMock as any,
            fileDownloadService as any,
            null,
            ipxNotificationService as any,
            taskMenuProvider as any,
            searchTypeActionMenuProvider as any,
            searchHelperService as any,
            reminderActionProvier as any,
            commonServiceMock as any,
            modalService as any,
            adhocDateService as any,
            attachmentModalService as any,
            attachmentPopupService as any,
            localDatePipe,
            searchPersistenceServiceMock as any
        );

        component.viewData = {
            q: '',
            permissions: {},
            isExternal: false,
            filter: '',
            queryContext: 970,
            criteria: new Criteria(),
            timePeriods: [{ id: 1, description: '', fromDate: new Date(), toDate: new Date() }],
            query: { description: 'My Tasks', key: -27, presentationId: 123, searchName: 'My Tasks', tabSequence: 1 },
            maintainEventNotes: true,
            selectedColumns: [{ columnKey: 11, sortDirection: 'ASC' }, { columnKey: 45, sortDirection: 'DESC' }],
            reminderDeleteButton: 1,
            maintainTaskPlannerSearch: true,
            maintainTaskPlannerSearchPermission: { update: false, insert: true },
            exportLimit: 5,
            autoRefreshGrid: true,
            canViewAttachments: true,
            canAddCaseAttachments: false,
            showLinksForInprotechWeb: true,
            provideDueDateInstructions: null,
            showReminderComments: true
        };
        tab = { isPublic: true, description: 'My Tasks Tab', key: -27, presentationId: 123, searchName: 'Tab', tabSequence: 1, queryKey: -27 };
        const tab1 = { description: 'My Tasks Tab 1', key: -28, presentationId: 1283, searchName: 'Tab 1', tabSequence: 2, queryKey: -28 };
        persistenceService.getTabBySequence = jest.fn().mockReturnValue(tab);
        component.activeQueryKey = -27;
        persistenceService.tabs = [tab, tab1];
        component.gridOptions = new IpxGridOptionsMock() as any;
        component.detailTemplate = null;
        component.filterForm = new NgForm(null, null);
        component._resultsGrid = new IpxKendoGridComponentMock() as any;
        component.activeTab = tab;
        component.activeTab.savedSearch = {
            query: new QueryData(),
            criteria: new Criteria()
        };
        component.activeTab.savedSearch.criteria.dateFilter = new DateRange();
        component.activeTab.defaultTimePeriods = [];
        component.activeTab.builderFormData = {};
        component.activeTab.filter = { searchRequest: { anySearch: { operator: 2, value: component.viewData.q } } };
        component.activeTab.defaultTimePeriods = [{
            sequence: 1,
            defaultTimePeriod: {
                fromDate: new Date(),
                toDate: new Date(),
                id: 1
            }
        }];
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate initializeTab', () => {
        component.initializeTab(tab, true);
        expect(component.isPublic).toEqual(true);
        const defaultCriteria: any = { searchRequest: { anySearch: { operator: 2, value: component.viewData.q } } };
        expect(component.activeTab.filter).toEqual(defaultCriteria);
        expect(taskPlannerService.getSavedSearchQuery).toHaveBeenCalledWith(-27, component.activeTab.filter);
        expect(taskPlannerService.showKeepOnTopNotes).toBeCalled();
    });

    it('validate onSavedSearchChange', () => {
        const query = { description: 'My Tasks', key: -27, presentationId: 123, searchName: 'My Tasks' };
        jest.spyOn(component, 'updateTabState');
        component.onSavedSearchChange(tab);
        expect(taskPlannerService.getSavedSearchQuery).toHaveBeenCalledWith(query.key, component.activeTab.filter);
        expect(component.updateTabState).toBeCalled();
    });

    it('validate dataItemClicked', () => {
        const selected = { caseKey: 210, taskPlannerRowKey: 'C^123^xyz^' };
        component.dataItemClicked(selected);
        expect(component.selectedCaseKey).toEqual(selected.caseKey.toString());
        expect(component.taskPlannerRowKey).toEqual(selected.taskPlannerRowKey.toString());
        expect(taskPlannerService.rowSelected.next).toBeCalledWith(component.selectedCaseKey);
        expect(taskPlannerService.taskPlannerRowKey.next).toBeCalledWith(component.taskPlannerRowKey);
    });

    it('validate getEncodeLinkData with ownerKey', () => {
        const column = { columnItemId: 'Owner' };
        const data = { ownerKey: 21 };
        const result = component.getEncodeLinkData(column, data);
        const expetedUrl = 'api/search/redirect?linkData=' +
            encodeURIComponent(JSON.stringify({ nameKey: 21 }));
        expect(result).toEqual(expetedUrl);
    });

    it('validate getEncodeLinkData with StaffMember', () => {
        const column = { columnItemId: 'StaffMember' };
        const data = { staffMemberKey: 20 };
        const result = component.getEncodeLinkData(column, data);
        const expetedUrl = 'api/search/redirect?linkData=' +
            encodeURIComponent(JSON.stringify({ nameKey: 20 }));
        expect(result).toEqual(expetedUrl);
    });

    it('validate getCssClassForDueDate with overdue date', () => {
        const column = { columnItemId: 'DueDate' };
        const dataItem = { duedate__9730_: '2020-09-22T00:00:00', isDueDatePast: true };
        const result = component.getCssClassForDueDate(column, dataItem);
        expect(result).toEqual('text-danger text-black-bold text-nowrap');
    });

    it('validate getCssClassForDueDate with today due date', () => {
        const column = { columnItemId: 'DueDate' };
        const dataItem = { duedate__9730_: '2020-09-22T00:00:00', isDueDateToday: true };
        const result = component.getCssClassForDueDate(column, dataItem);
        expect(result).toEqual('text-black-bold text-nowrap');
    });

    it('validate getCssClassForDueDate for caseRef column', () => {
        const column = { columnItemId: 'CaseReference' };
        const dataItem = { duedate__9730_: '2020-09-22T00:00:00', isDueDatePast: true };
        const result = component.getCssClassForDueDate(column, dataItem);
        expect(result).toEqual('text-nowrap');
    });

    it('validate hasBooleanValue with defined data', () => {
        const data = 'true';
        const result = component.hasBooleanValue(data);
        expect(result).toBeTruthy();
    });

    it('validate hasBooleanValue with undefined data', () => {
        const data = undefined;
        const result = component.hasBooleanValue(data);
        expect(result).toBeFalsy();
    });

    it('validate onDateRangeChange for from date', () => {
        const date = new Date();
        component.loaded = true;
        component.activeTabSequence = 1;
        component.activeTab.selectedPeriodId = 1;
        component.onDateRangeChange(date, 'from');
        expect(component.activeTab.defaultTimePeriods[0].defaultTimePeriod.fromDate).toEqual(date);
    });

    it('date range should be selected', () => {
        component.loaded = true;
        component.activeTabSequence = 1;
        component.activeTab.timePeriods = [
            { id: 1, description: 'date range', fromDate: new Date(), toDate: new Date() },
            { id: 2, description: 'This week', fromDate: new Date(), toDate: new Date() }
        ];
        component.activeTab.selectedPeriodId = 2;
        component.onDateRangeChange(null, 'to');
        expect(component.activeTab.selectedPeriodId).toEqual(1);
        expect(component.activeTab.defaultTimePeriods[0].defaultTimePeriod.toDate).toBeNull();
    });

    it('validate onDateRangeChange for to date with null', () => {
        spyOn(component.gridOptions, '_search');
        component.loaded = true;
        component.activeTabSequence = 1;
        component.activeTab.selectedPeriodId = 1;
        component.onDateRangeChange(null, 'to');
        expect(component.activeTab.defaultTimePeriods[0].defaultTimePeriod.toDate).toEqual(null);
    });

    it('validate onDateRangeChange for to date', () => {
        const date = new Date();
        component.loaded = true;
        component.activeTab.selectedPeriodId = 1;
        component.activeTab.defaultTimePeriods = [{ queryKey: component.activeQueryKey, defaultTimePeriod: { id: 1, description: '', fromDate: new Date(), toDate: new Date() } }];
        component.onDateRangeChange(date, 'to');
        expect(component.activeTab.selectedPeriodId).toEqual(component.activeTab.defaultTimePeriods[0].defaultTimePeriod.id);
    });

    it('validate onNameChanged', () => {
        spyOn(component, 'refreshGrid');
        component.loaded = true;
        component.onNameChanged();
        expect(component._resultsGrid.clearSelection).toHaveBeenCalled();
    });

    it('validate onTimePeriodChange', () => {
        component.onTimePeriodChange(1);
        expect(component.activeTab.savedSearch.criteria.dateFilter.from).toBeUndefined();
    });

    it('validate hasGridLoaded', () => {
        component.loaded = true;
        const result = component.hasGridLoaded();
        expect(result).toBeTruthy();
    });

    it('validate setQuickFilterDirty', () => {
        component.setQuickFilterDirty('nameKey');
        expect(component.activeTab.dirtyQuickFilters.get('nameKey')).toBeTruthy();
    });

    it('validate setQuickFiltersToPristine', () => {
        component.setQuickFilterDirty('nameKey');
        component.setQuickFiltersToPristine();
        expect(component.activeTab.dirtyQuickFilters.get('nameKey')).toBeFalsy();
    });

    it('validate isQuickFilterDirty for dirty control', () => {
        component.setQuickFilterDirty('nameKey');
        const result = component.isQuickFilterDirty('nameKey');
        expect(result).toBeTruthy();
    });

    it('validate isQuickFilterDirty for pristine control', () => {
        const result = component.isQuickFilterDirty('nameKey');
        expect(result).toBeFalsy();
    });

    it('validate openPresentation', () => {
        component.activeTabSequence = 1;
        component.isPublic = false;
        component.openPresentation();
        expect(stateService.go).toHaveBeenCalledWith('searchpresentation',
            {
                activeTabSeq: 1,
                filter: {
                    filterCriteria: component.activeTab.filter, formData: component.activeTab.builderFormData
                },
                isPublic: false,
                queryContextKey: queryContextKeyEnum.taskPlannerSearch,
                queryKey: component.activeQueryKey, queryName: 'Tab'
            });
    });

    it('validate detailTemplate has been defined', () => {
        component.loaded = true;
        const grid = component.gridOptions;
        expect(grid).toBeDefined();
        expect(component.detailTemplate).toBeDefined();
    });

    it('init Menu Actions', () => {
        component.initMenuActions();
        expect(component.bulkActions.length).toEqual(1);
        expect(component.bulkActions[0].items.length).toEqual(3);
    });

    it('should call export excel', () => {
        exportFormat = ReportExportFormat.Excel;
        component.queryParams = { skip: null, take: null, filters: [] };
        component._resultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
            isAllPageSelect: false,
            allSelectedItems: [{ id: 1, text: 'database', selected: true, rowKey: '1' }, { id: 2, text: 'abc', selected: true, rowKey: '2' }, { id: 3, text: 'xyz', selected: true, rowKey: '3' }, { id: 4, text: 'pqr', selected: true, rowKey: '4' }],
            allDeSelectedItems: []
        });
        component.rowKeyField = 'caseKey';
        component.activeTab.filter = {
            searchRequest: [
                {
                    anySearch: {
                        operator: 2
                    }
                }
            ]
        };
        component.searchConfiguration = {
            allowExportFiltering: true,
            baseApiRoute: 'string',
            rowKeyField: 'string',
            pageTitle: 'string',
            hasPreview: false,
            searchType: 'string',
            imageApiKey: 'string',
            getExportObject: 'any',
            selectableSetting: 'any',
            // tslint:disable-next-line: no-empty
            customCheckboxSelection: () => { }
        };
        component.activeTab.filter = { dueDateFilter: null };
        component.export(exportFormat);
        expect(searchExportServiceMock.export).toHaveBeenCalled();
    });

    it('should call export pdf', () => {
        exportFormat = ReportExportFormat.PDF;
        component.queryParams = { skip: null, take: null, filters: [] };
        component._resultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
            isAllPageSelect: false,
            allSelectedItems: [{ id: 1, text: 'database', selected: true, rowKey: '1' }, { id: 2, text: 'abc', selected: true, rowKey: '2' }, { id: 3, text: 'xyz', selected: true, rowKey: '3' }, { id: 4, text: 'pqr', selected: true, rowKey: '4' }],
            allDeSelectedItems: []
        });
        component.rowKeyField = 'caseKey';
        component.activeTab.filter = {
            searchRequest: [
                {
                    anySearch: {
                        operator: 2
                    }
                }
            ]
        };
        component.searchConfiguration = {
            allowExportFiltering: true,
            baseApiRoute: 'string',
            rowKeyField: 'string',
            pageTitle: 'string',
            hasPreview: false,
            searchType: 'string',
            imageApiKey: 'string',
            getExportObject: 'any',
            selectableSetting: 'any',
            // tslint:disable-next-line: no-empty
            customCheckboxSelection: () => { }
        };
        component.activeTab.filter = { dueDateFilter: null };
        component.export(exportFormat);
        expect(searchExportServiceMock.export).toHaveBeenCalled();
    });

    it('should call export Word', () => {
        exportFormat = ReportExportFormat.Word;
        component.queryParams = { skip: null, take: null, filters: [] };
        component._resultsGrid.getRowSelectionParams = jest.fn().mockReturnValue({
            isAllPageSelect: false,
            allSelectedItems: [{ id: 1, text: 'database', selected: true, rowKey: '1' }, { id: 2, text: 'abc', selected: true, rowKey: '2' }, { id: 3, text: 'xyz', selected: true, rowKey: '3' }, { id: 4, text: 'pqr', selected: true, rowKey: '4' }],
            allDeSelectedItems: []
        });
        component.rowKeyField = 'caseKey';
        component.activeTab.filter = {
            searchRequest: [
                {
                    anySearch: {
                        operator: 2
                    }
                }
            ]
        };
        component.searchConfiguration = {
            allowExportFiltering: true,
            baseApiRoute: 'string',
            rowKeyField: 'string',
            pageTitle: 'string',
            hasPreview: false,
            searchType: 'string',
            imageApiKey: 'string',
            getExportObject: 'any',
            selectableSetting: 'any',
            // tslint:disable-next-line: no-empty
            customCheckboxSelection: () => { }
        };
        component.activeTab.filter = { dueDateFilter: null };
        component.export(exportFormat);
        expect(searchExportServiceMock.export).toHaveBeenCalled();
    });

    it('validate getTaskPlannerStateParams', () => {
        const result = component.getTaskPlannerStateParams();
        expect(result.filterCriteria).toEqual(component.activeTab.filter);
        expect(result.formData).toEqual(component.activeTab.builderFormData);
        expect(result.activeTabSeq).toEqual(component.activeTabSequence);
        expect(result.isPublic).toEqual(component.isPublic);
    });

    it('Should call handelOnEventNoteUpdate', () => {
        spyOn(component.updateEventNoteIcon, 'next');
        component.handelOnEventNoteUpdate(1);
        expect(component.updateEventNoteIcon.next).toHaveBeenCalledWith(1);
    });

    it('verify handleOnTaskDetailChange method', () => {
        const event = { isDirty: true, rowKey: 'C^23^55C' };
        component.handleOnTaskDetailChange(event);
        expect(component.dirtyNotesAndComments.get(event.rowKey)).toBeTruthy();
    });

    it('verify hasAnyNoteOrCommentChanged with unsaved notes', () => {
        component.dirtyNotesAndComments.set('C^232^4N', true);
        const result = component.hasAnyNoteOrCommentChanged();
        expect(result).toBeTruthy();
    });

    it('verify hasAnyNoteOrCommentChanged with saved notes', () => {
        component.dirtyNotesAndComments.set('C^232^4N', false);
        component.dirtyNotesAndComments.set('C^99^5C', false);
        const result = component.hasAnyNoteOrCommentChanged();
        expect(result).toBeFalsy();
    });

    it('Should call isPicklistSearch', () => {
        component.isPicklistSearch();
        expect(persistenceService.isPicklistSearch).toBeTruthy();
    });

    describe('Time Recording task menus - when task security is given', () => {
        it('record time menus are added, when user has task security', () => {
            component.displayTaskItems({ caseKey: 10 });
            expect(component.taskItems.length).toBe(3);
            expect(component.taskItems[0].id).toBe('RecordTime');
            expect(component.taskItems[1].id).toBe('RecordTimeWithTimer');
            expect(component.taskItems[2].id).toBe('caseWebLinks');
        });

        it('record time menu, opens a link on trigger', () => {
            const record = { caseKey: 10 };
            component.displayTaskItems(record);
            const dataItem = { event: { item: component.taskItems[0] }, dataItem: record };
            component.onMenuItemSelected(dataItem);
            expect(dataItem.event.item.id).toEqual('RecordTime');
        });
    });

    it('should call openAdHocDate', () => {
        component.openAdHocDate();
        adhocDateService.viewData().subscribe((response: any) => {
            expect(modalService.openModal).toHaveBeenCalledWith(response);
        });
    });

    it('should open the attachments window as popup', () => {
        const dataItem = {
            caseKey: -101,
            eventKey: 777,
            eventCycle: 123
        };

        component.openAttachmentWindow(dataItem);

        expect(attachmentModalService.displayAttachmentModal).toHaveBeenCalled();
        expect(attachmentModalService.displayAttachmentModal.mock.calls[0][0]).toEqual('case');
        expect(attachmentModalService.displayAttachmentModal.mock.calls[0][1]).toEqual(dataItem.caseKey);
        expect(attachmentModalService.displayAttachmentModal.mock.calls[0][2].eventKey).toEqual(dataItem.eventKey);
        expect(attachmentModalService.displayAttachmentModal.mock.calls[0][2].eventCycle).toEqual(dataItem.eventCycle);
    });

    it('should refresh grid, on attachments changed', fakeAsync(() => {
        attachmentModalService.attachmentsModified = of(true).pipe(delay(10));
        taskPlannerService.autoRefreshGrid = true;
        component.ngOnInit();

        tick(100);

        expect(component.gridOptions._search).toHaveBeenCalled();
        expect(attachmentPopupService.clearCache).toHaveBeenCalled();
    }));

    it('should not refresh grid on attachments changes, if user preference to autoRefresh is turned off', fakeAsync(() => {
        component.viewData.autoRefreshGrid = false;
        attachmentModalService.attachmentsModified = of(true).pipe(delay(10));
        component.ngOnInit();

        tick(100);

        expect(component.gridOptions._search).not.toHaveBeenCalled();

        flush();
    }));

    it('Should call prepareNotesAndCommentsText', () => {
        const dataItem = {
            lastUpdatedReminderComment: undefined,
            taskPlannerRowKey: 'C^4464^131'
        };
        const result = component.prepareNotesAndCommentsText(dataItem);
        expect(result).toBeFalsy();
    });

    it('Should call prepareNotesAndCommentsText to prepare remindercomments tooltip', () => {
        const dataItem = {
            lastUpdatedReminderComment: '2021-09-22T13:07:20.35',
            taskPlannerRowKey: 'C^4464^131'
        };
        const result = component.prepareNotesAndCommentsText(dataItem);
        expect(result).toBeTruthy();
    });

    it('Should call prepareNotesAndCommentsText to prepare eventNotes tooltip', () => {
        const dataItem = {
            lastUpdatedEventNoteTimeStamp: '2021-09-22T12:44:13.43',
            taskPlannerRowKey: 'C^4464^131'
        };
        const result = component.prepareNotesAndCommentsText(dataItem);
        expect(result).toBeTruthy();
    });
    it('Should callExpandNotesAndReminder', () => {
        component.gridOptions.groups = [];
        component.callExpandNotesAndReminder(1, 'C^4464^131');
        expect(component.taskPlannerRowKey).toEqual('C^4464^131');
        expect(component.gridOptions.detailTemplate).toEqual(null);
    });
    it('Should callExpandNotesAndReminder with grouping', () => {
        component.gridOptions.groups = [{
            field: 'countryname__9713_',
            aggregates: []
        }];
        component.groupDetailTemplate = null;
        component.callExpandNotesAndReminder(1, 'C^4464^131');
        expect(component.taskPlannerRowKey).toEqual('C^4464^131');
        expect(component.gridOptions.detailTemplate).toEqual(null);
    });
});
