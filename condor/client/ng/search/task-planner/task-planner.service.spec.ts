import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { KeepOnTopNotesViewService, KotViewProgramEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { RightBarNavServiceMock } from 'rightbarnav/rightbarnavservice.mock';
import { of } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';
import { queryContextKeyEnum, SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { ReportExportFormat } from 'search/results/report-export.format';
import { SavedTaskPlannerData } from './task-planner-search-builder/search-builder.data';
import { ReminderRequestType } from './task-planner.data';
import { TaskPlannerService } from './task-planner.service';

describe('TaskPlannerService', () => {
    let service: TaskPlannerService;
    let rightBarNavService: RightBarNavServiceMock;
    let kotService: KeepOnTopNotesViewService;
    let httpMock = new HttpClientMock();
    let exportFormat: ReportExportFormat;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        httpMock.get.mockReturnValue(of({}));
        rightBarNavService = new RightBarNavServiceMock();
        kotService = new KeepOnTopNotesViewService(httpMock as any);
        SearchTypeConfigProvider.savedConfig = { baseApiRoute: 'api/taskplanner/' } as any;
        service = new TaskPlannerService(httpMock as any, rightBarNavService as any, kotService);
        service.previousStateParam = {
            filterCriteria: {
                searchRequest: {
                    include: {},
                    dates: {}
                }
            }
        };
    });
    it('should create the service', async(() => {
        expect(service).toBeTruthy();
    }));

    it('validate getColumns$', () => {
        const queryKey = 11;
        const queryContext = 970;
        const selectedColumns = null;
        service.getColumns$(queryKey, selectedColumns, queryContext);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/columns', {
            queryKey,
            presentationType: null,
            selectedColumns,
            queryContext
        });
    });

    it('validate getSavedSearch', () => {
        const queryKey = -27;
        const params = {};
        const queryContext = 970;
        const selectedColumns = null;
        service.getSavedSearch$(queryKey, params, queryContext, null, selectedColumns);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/savedSearch', {
            queryKey,
            params,
            queryContext,
            criteria: null,
            selectedColumns
        });
    });

    it('validate getSearchResultsViewData', () => {
        const response = {
            q: '',
            permissions: {},
            isExternal: false,
            filter: '',
            queryContext: 970,
            userName: {},
            query: { description: 'My Tasks', key: -27, presentationId: 123, searchName: 'My Tasks' }
        };

        httpMock.post.mockReturnValue(of(response));
        service.getSearchResultsViewData().subscribe(
            result => {
                expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/getTaskPlannerTabs');
                expect(result).toBeTruthy();
                expect(result).toBe(response);
            }
        );
    });
    it('validate getSavedSearchQuery', () => {
        const queryKey = -27;
        service.getSavedSearchQuery(queryKey, service.previousStateParam);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/savedSearchQuery', {
            queryKey,
            queryContext: queryContextKeyEnum.taskPlannerSearch.toString(),
            filterCriteria: service.previousStateParam
        });
    });

    describe('show keep on top notes', () => {
        it('get Kot notes', () => {
            service.showKeepOnTopNotes();
            service.rowSelectedForKot.pipe(
                debounceTime(300),
                distinctUntilChanged(),
                switchMap((selected) => {
                    expect(rightBarNavService.registerKot).toBeCalledWith(null);
                    expect(kotService.getKotForCaseView).toBeCalled();
                    expect(selected).toBeDefined();
                })
            );
            kotService.getKotForCaseView('123', KotViewProgramEnum.Case).subscribe((res) => {
                expect(res).toBeDefined();
                expect(rightBarNavService.registerKot).toBeCalled();
            });
        });
    });

    it('validate getColumnFilterData', () => {
        const queryKey = -27;
        const filter = {};
        const column = {};
        const params = {};
        const selectedColumns = [];
        const queryContext = 970;
        service.getColumnFilterData(filter, column, params, queryKey, selectedColumns, queryContext);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/filterData',
            {
                criteria: filter,
                params,
                column,
                queryKey,
                queryContext,
                selectedColumns
            });
    });

    it('validate getBelongingToOptions', () => {
        const result = service.getBelongingToOptions();
        expect(result.length).toEqual(5);
        expect(result[0].key).toEqual('myself');
        expect(result[3].key).toEqual('otherTeams');
        expect(result[4].key).toEqual('allNames');
    });

    it('validate getSearchBuilderViewData', () => {
        const response = {
            ImportanceLevels: [{ key: 1, value: 'Normal' }, { key: 2, value: 'Important' }]
        };

        httpMock.get.mockReturnValue(of(response));
        service.getSearchBuilderViewData().subscribe(
            result => {
                expect(result).toBe(response);
            }
        );
    });

    it('get reminder comments', () => {
        const response = {
            ImportanceLevels: [{ StaffNameCode: 1, StaffDisplayName: 'Danial', Comments: 'Good' },
            { StaffNameCode: 2, StaffDisplayName: 'John', Comments: 'Perfect' }]
        };
        const rowKey = 'C^551^-22^1';
        httpMock.get.mockReturnValue(of(response));
        service.reminderComments(rowKey).subscribe(
            result => {
                expect(result).toBe(response);
            }
        );
        expect(httpMock.get).toHaveBeenCalledWith('api/taskplanner/comments/' + rowKey);
    });

    it('get reminders count', () => {
        const response = 1;
        const rowKey = 'C^551^-22^1';
        httpMock.get.mockReturnValue(of(response));
        service.reminderCommentsCount(rowKey).subscribe(
            result => {
                expect(result).toBe(response);
            }
        );
        expect(httpMock.get).toHaveBeenCalledWith('api/taskplanner/comments/' + rowKey + '/count');
    });

    it('save reminder comment', () => {
        const response = {
            result: 'success'
        };
        const reminderComment = {
            taskPlannerRowKey: 'C^551^-22^1',
            comments: 'comments from george grey'
        };
        httpMock.post.mockReturnValue(of(response));
        service.saveReminderComment(reminderComment).subscribe(
            result => {
                expect(result).toBe(response);
            }
        );
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/comments/update', reminderComment);
    });

    it('validate getEventNoteTypes', () => {
        service.getEventNoteTypes$();
        expect(httpMock.get).toHaveBeenCalledWith('api/case/event-note-types');
    });

    it('should call the exportToExcel method', () => {
        const filter = [{ caseKeys: { operator: 0, value: '-486,-470' } }];
        const searchName = 'US Trademark';
        const queryKey = '36';
        const queryContextKey = 2;
        exportFormat = ReportExportFormat.Excel;
        const params = { skip: null, take: null };
        spyOn(httpMock, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
        service.export(filter, params, searchName, queryKey, queryContextKey, null, exportFormat, 1);
        expect(httpMock.post).toHaveBeenCalled();
    });

    it('should call the exportTo PDF method', () => {
        const filter = [{ caseKeys: { operator: 0, value: '-486,-470' } }];
        const searchName = 'US Trademark';
        const queryKey = '36';
        const queryContextKey = 2;
        exportFormat = ReportExportFormat.PDF;
        const params = { skip: null, take: null };
        spyOn(httpMock, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
        service.export(filter, params, searchName, queryKey, queryContextKey, null, exportFormat, 1);
        expect(httpMock.post).toHaveBeenCalled();
    });

    it('should call the exportTo word method', () => {
        const filter = [{ caseKeys: { operator: 0, value: '-486,-470' } }];
        const searchName = 'US Trademark';
        const queryKey = '36';
        const queryContextKey = 2;
        exportFormat = ReportExportFormat.Word;
        const params = { skip: null, take: null };
        spyOn(httpMock, 'post').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
        service.export(filter, params, searchName, queryKey, queryContextKey, null, exportFormat, 1);
        expect(httpMock.post).toHaveBeenCalled();
    });

    it('validate dismissReminders', () => {
        const taskPlannerRowKey = 'A^123^333^44^78';
        service.dismissReminders([taskPlannerRowKey], null, ReminderRequestType.InlineTask);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/dismissReminders', { taskPlannerRowKeys: [taskPlannerRowKey], searchRequestParams: null, requestType: ReminderRequestType.InlineTask });
    });

    it('validate deferReminders', () => {
        const taskPlannerRowKey = 'A^123^333^44^78';
        service.deferReminders(ReminderRequestType.BulkAction, [taskPlannerRowKey], null, null);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/deferReminders', { taskPlannerRowKeys: [taskPlannerRowKey], holdUntilDate: null, requestType: ReminderRequestType.BulkAction, searchRequestParams: null });
    });

    it('validate markAsReadOrUnread', () => {
        const taskPlannerRowKey = 'A^123^333^44^78';
        service.markAsReadOrUnread([taskPlannerRowKey], true, null);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/readOrUnreadReminders', { taskPlannerRowKeys: [taskPlannerRowKey], isRead: true, searchRequestParams: null });
    });

    it('validate changeDueDateResponsibility', () => {
        const taskPlannerRowKey = 'C^123^333^44^78';
        service.changeDueDateResponsibility([taskPlannerRowKey], 12, null);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/changeDueDateResponsibility', { taskPlannerRowKeys: [taskPlannerRowKey], toNameId: 12, searchRequestParams: null });
    });

    it('validate getDueDateResponsibility', () => {
        const taskPlannerRowKey = 'C^123^333^44^78';
        service.getDueDateResponsibility(taskPlannerRowKey);
        expect(httpMock.get).toHaveBeenCalledWith('api/taskplanner/getDueDateResponsibility/' + taskPlannerRowKey);
    });

    it('validate forwardReminders', () => {
        const taskPlannerRowKey = 'C^123^333^44^78';
        service.forwardReminders([taskPlannerRowKey], [12, 13], null);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/forwardReminders', { taskPlannerRowKeys: [taskPlannerRowKey], toNameIds: [12, 13], searchRequestParams: null });
    });

    it('validate getUserPreferenceViewData', () => {
        service.getUserPreferenceViewData();
        expect(httpMock.get).toHaveBeenCalledWith('api/taskplanner/userPreference/viewData');
    });

    it('validate setUserPreference', () => {
        const data = { autoRefreshGrid: true, tabs: [] };
        service.setUserPreference(data);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/userPreference/set', data);
    });

    it('validate getEmailContent', () => {
        const taskPlannerRowKey = 'C^123^333';
        service.getEmailContent([taskPlannerRowKey], null);
        expect(httpMock.post).toHaveBeenCalledWith('api/taskplanner/getEmailContent', { taskPlannerRowKeys: [taskPlannerRowKey], searchRequestParams: null });
    });

    it('validate hasEmployeeReminder for adhoc date', () => {
        const dataItem = { taskPlannerRowKey: 'A^123^333^44^78' };
        const result = service.hasEmployeeReminder(dataItem);
        expect(result).toBeTruthy();
    });

    it('validate hasEmployeeReminder for due date', () => {
        const dataItem = { taskPlannerRowKey: 'C^123^' };
        const result = service.hasEmployeeReminder(dataItem);
        expect(result).toBeFalsy();
    });

    it('validate isReminderOrDueDate with duedate', () => {
        const dataItem = { taskPlannerRowKey: 'C^123^333^44^' };
        const result = service.isReminderOrDueDate(dataItem);
        expect(result).toBeTruthy();
    });

    it('validate isReminderOrDueDate with adhoc', () => {
        const dataItem = { taskPlannerRowKey: 'A^123^333^44^' };
        const result = service.isReminderOrDueDate(dataItem);
        expect(result).toBeFalsy();
    });

    it('call getSavedTaskPlannerData', () => {
        const request = { queryKey: -31 };
        const response = new SavedTaskPlannerData();
        response.queryKey = -31;
        response.queryName = 'saved Task planner';
        response.isPublic = true;
        response.formData = { belongingToFilter: { value: '', actingAs: {} } };
        httpMock.get.mockReturnValue(of(response));
        service.getSavedTaskPlannerData = jest.fn().mockReturnValue(of(response));
        service.getSavedTaskPlannerData(request).subscribe(
            result => {
                expect(result).toBeTruthy();
                expect(result.queryKey).toBe(-31);
                expect(result.isPublic).toBe(true);
            }
        );
    });
    it('Delete saved search', () => {
        const response: any = true;
        const queryKey = -31;
        httpMock.get.mockReturnValue(of(response));
        service.DeleteSavedSearch(queryKey).subscribe(
            result => {
                expect(result).toEqual(response);
            }
        );
    });

    it('validate isCustomSearch if queryKey is null', () => {
        service.previousStateParam = { searchBuilder: true, queryKey: null };
        expect(service.isCustomSearch()).toEqual(true);
    });
    it('validate isCustomSearch if come from presentation page with dirty', () => {
        service.previousStateParam = { searchBuilder: true, queryKey: -31, formData: { form: 1 }, isFormDirty: true };
        expect(service.isCustomSearch()).toEqual(true);
    });
    it('validate isCustomSearch if come from presentation page with not dirty', () => {
        service.previousStateParam = {
            searchBuilder: true, queryKey: -31, formData: { form: 1 },
            isFormDirty: false, isSelectedColumnChange: false, selectedColumns: {}
        };
        expect(service.isCustomSearch()).toEqual(false);
    });

    it('validate isCustomSearch if come from search builder page with dirty', () => {
        service.previousStateParam = { searchBuilder: true, queryKey: -31, isSelectedColumnChange: true, selectedColumns: { form: 1 } };
        expect(service.isCustomSearch()).toEqual(true);
    });
});