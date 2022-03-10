import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { KeepOnTopNotesViewService, KotViewProgramEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { RightBarNavService } from 'rightbarnav/rightbarnav.service';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { concatMap, debounceTime, distinctUntilChanged, map, switchMap, tap } from 'rxjs/operators';
import { SelectedColumn } from 'search/presentation/search-presentation.model';
import { ReportExportFormat } from 'search/results/report-export.format';
import { SearchResultColumn } from 'search/results/search-results.model';
import { SaveSearchEntity } from 'search/savedsearch/saved-search.model';
import * as _ from 'underscore';
import { queryContextKeyEnum, SearchTypeConfigProvider } from './../common/search-type-config.provider';
import { SavedTaskPlannerData, SearchBuilderViewData } from './task-planner-search-builder/search-builder.data';
import { ReminderEmailContent, ReminderRequestType, ReminderResult, SavedSearchData, TaskPlannerItemType, TaskPlannerPreferenceModel, TaskPlannerViewData, UserPreferenceViewData } from './task-planner.data';

@Injectable()
export class TaskPlannerService {
  baseApiRoute = 'api/taskplanner';

  rowSelected = new BehaviorSubject(null);
  taskPlannerRowKey = new BehaviorSubject(null);
  private readonly _previousStateParam$ = new BehaviorSubject(null);
  private _taskPlannerStateParam: any;
  private _autoRefreshGrid: boolean;
  rowSelectedForKot = new BehaviorSubject(null);
  reminderDetailCount$ = new BehaviorSubject<any>(null);
  eventNoteDetailCount$ = new BehaviorSubject<any>(null);
  isCommentDirty$ = new BehaviorSubject<any>(null);
  onActionComplete$ = new BehaviorSubject(null);
  isSavedSearchChangeEvent = false;
  isSavedSearchDeleted = false;
  adHocDateCheckedChangedt$ = new BehaviorSubject<any>(null);

  get previousStateParam(): any {
    return this._previousStateParam$.getValue();
  }

  taskPlannerTabs: any;

  set previousStateParam(value: any) {
    this._previousStateParam$.next({ ...value });
  }
  get taskPlannerStateParam(): any {
    return this._taskPlannerStateParam;
  }

  set taskPlannerStateParam(value: any) {
    this._taskPlannerStateParam = { ...value };
  }

  get autoRefreshGrid(): boolean {
    return this._autoRefreshGrid;
  }
  set autoRefreshGrid(value: boolean) {
    this._autoRefreshGrid = value;
  }

  constructor(private readonly http: HttpClient,
    private readonly rightBarNavService: RightBarNavService,
    private readonly kotViewService: KeepOnTopNotesViewService) { }

  export(filter: any, params: any, searchName: any, queryKey: any, queryContext: number,
    selectedColumns: Array<SelectedColumn>,
    exportFormat: ReportExportFormat, contentId: number, deselectedIds?: any): Observable<any> {

    return this.http
      .post(
        `${this.baseApiRoute}/export`,
        {
          criteria: (filter instanceof String || typeof filter === 'string') ? { XmlSearchRequest: filter } : filter,
          params,
          searchName,
          queryKey,
          queryContext,
          selectedColumns,
          deselectedIds,
          exportFormat,
          contentId
        }
      );
  }

  getBelongingToOptions = (): Array<any> => {
    const data = [
      { key: 'myself', value: 'taskPlanner.searchBuilder.general.myself' },
      { key: 'myTeam', value: 'taskPlanner.searchBuilder.general.myTeam' },
      { key: 'otherNames', value: 'taskPlanner.searchBuilder.general.otherNames' },
      { key: 'otherTeams', value: 'taskPlanner.searchBuilder.general.otherTeams' },
      { key: 'allNames', value: 'taskPlanner.searchBuilder.general.allNames' }
    ];

    return data;
  };

  getSearchResultsViewData = (): Observable<TaskPlannerViewData> => {
    let defaultQueryKey;

    if (this.previousStateParam && this.previousStateParam.savedSearch && this.previousStateParam.savedSearch.query) {
      defaultQueryKey = this.previousStateParam.savedSearch.query.key;

      return this.getTaskPlannerViewData(defaultQueryKey);
    } else if (this.previousStateParam && this.previousStateParam.searchBuilder && this.previousStateParam.queryKey) {

      return this.getTaskPlannerViewData(this.previousStateParam.queryKey);
    } else if (this.previousStateParam && this.previousStateParam.searchBuilder && !this.previousStateParam.queryKey) {

      return this.getTaskPlannerViewData(null);
    }

    return this.http.post(`${this.baseApiRoute}/getTaskPlannerTabs`, {
      queryContext: queryContextKeyEnum.taskPlannerSearch.toString()
    }).pipe(
      tap(res => {
        this.taskPlannerTabs = res;
        defaultQueryKey = res[0].key;
      }),
      concatMap(() =>
        this.getTaskPlannerViewData(defaultQueryKey)
      )
    );
  };

  getTaskPlannerViewData = (defaultQueryKey: number): Observable<TaskPlannerViewData> => {
    return this.http
      .post(`${this.baseApiRoute}/viewdata`, {
        queryKey: defaultQueryKey,
        queryContext: queryContextKeyEnum.taskPlannerSearch.toString(),
        filterCriteria: this.previousStateParam ? this.previousStateParam.filterCriteria : null
      })
      .pipe(
        map((response: TaskPlannerViewData) => {

          return {
            q: '',
            filter: this.previousStateParam ? this.previousStateParam.filterCriteria : null,
            queryContext: response.queryContext,
            isExternal: response.isExternal,
            selectedColumns: this.previousStateParam ? this.previousStateParam.selectedColumns : null,
            permissions: response.permissions,
            criteria: response.criteria,
            query: response.query,
            isPublic: response.isPublic,
            timePeriods: response.timePeriods,
            maintainEventNotes: response.maintainEventNotes,
            showReminderComments: response.showReminderComments,
            maintainReminderComments: response.maintainReminderComments,
            replaceEventNotes: response.replaceEventNotes,
            maintainEventNotesPermissions: response.maintainEventNotesPermissions,
            reminderDeleteButton: response.reminderDeleteButton,
            maintainTaskPlannerSearch: response.maintainTaskPlannerSearch,
            maintainTaskPlannerSearchPermission: response.maintainTaskPlannerSearchPermission,
            maintainPublicSearch: response.maintainPublicSearch,
            canFinaliseAdhocDate: response.canFinaliseAdhocDates,
            resolveReasons: response.resolveReasons,
            exportLimit: response.exportLimit,
            canCreateAdhocDate: response.canCreateAdhocDate,
            autoRefreshGrid: response.autoRefreshGrid,
            canViewAttachments: response.canViewAttachments,
            canAddCaseAttachments: response.canAddCaseAttachments,
            canMaintainAdhocDate: response.canMaintainAdhocDate,
            canChangeDueDateResponsibility: response.canChangeDueDateResponsibility,
            showLinksForInprotechWeb: response.showLinksForInprotechWeb,
            provideDueDateInstructions: response.provideDueDateInstructions
          };
        })
      );
  };

  getSearchBuilderViewData = (): Observable<SearchBuilderViewData> => {

    return this.http
      .get<SearchBuilderViewData>(`${this.baseApiRoute}/searchBuilder/viewData`);
  };

  getSavedSearchQuery = (queryKey: number, filterCriteria: any): Observable<SavedSearchData> => {

    return this.http
      .post<SavedSearchData>(`${this.baseApiRoute}/savedSearchQuery`, {
        queryKey,
        queryContext: queryContextKeyEnum.taskPlannerSearch.toString(),
        filterCriteria
      });
  };

  getColumns$(queryKey, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<Array<SearchResultColumn>> {

    return this.http.post<Array<SearchResultColumn>>(`${this.baseApiRoute}/columns`, {
      queryKey,
      presentationType: null,
      selectedColumns,
      queryContext
    });
  }

  getSavedSearch$(queryKey: number, params: any, queryContext: Number, criteria: any, selectedColumns: Array<any>): Observable<any> {

    return this.http.post(
      `${this.baseApiRoute}/savedSearch`, {
      queryKey,
      criteria,
      params,
      queryContext,
      selectedColumns
    }
    );
  }

  getColumnFilterData(filters: any, column: any, params: any, queryKey: number, selectedColumns: Array<SelectedColumn>, queryContext: Number): Observable<any> {

    return this.http.post(`${this.baseApiRoute}/filterData`, {
      criteria: filters,
      params,
      column,
      queryKey,
      queryContext,
      selectedColumns
    });
  }

  showKeepOnTopNotes(): any {
    this.rowSelectedForKot.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      switchMap(selected => {
        this.rightBarNavService.registerKot(null);
        if (selected && selected.id) {
          return this.kotViewService.getKotForCaseView(selected.id, KotViewProgramEnum.TaskPlanner, selected.type);
        }

        return of(null);
      })
    ).subscribe(res => {
      if (res) {
        this.rightBarNavService.registerKot(res.result);
      }
    });
  }

  reminderComments = (taskPlannerRowKey: string): any => {
    return this.http
      .get<any>(this.baseApiRoute + '/comments/' + taskPlannerRowKey);
  };

  reminderCommentsCount = (taskPlannerRowKey: string): any => {
    return this.http
      .get<number>(this.baseApiRoute + '/comments/' + taskPlannerRowKey + '/count');
  };

  saveReminderComment = (reminderComments: any): Observable<any> => {
    return this.http.post<any>(this.baseApiRoute + '/comments/update', reminderComments);
  };

  getUserPreferenceViewData = (): Observable<UserPreferenceViewData> => {
    return this.http.get<UserPreferenceViewData>(this.baseApiRoute + '/userPreference/viewData');
  };

  setUserPreference = (request: TaskPlannerPreferenceModel): Observable<any> => {
    return this.http.post(this.baseApiRoute + '/userPreference/set', request);
  };

  isCustomSearch = (): boolean => {
    const params = this.previousStateParam;

    if (params && params.searchBuilder && !params.queryKey) {
      return true;
    }

    return params && params.searchBuilder &&
      ((params.formData && !_.isEmpty(params.formData) && params.isFormDirty) || (params.isSelectedColumnChange && params.selectedColumns && !_.isEmpty(params.selectedColumns)));
  };

  getEventNotesDetails$(taskPlannerRowKey: string): Observable<any> {
    return this.http.get('api/case/eventNotesDetails', {
      params: new HttpParams()
        .set('taskPlannerRowKey', taskPlannerRowKey)
    });
  }

  getEventNoteTypes$(): Observable<any> {
    return this.http.get('api/case/event-note-types');
  }

  isPredefinedNoteTypeExist(): Observable<any> {
    return this.http.get('api/case/eventNotesDetails/isPredefinedNoteTypeExist');
  }

  siteControlId(): Observable<number> {
    return this.http.get<number>('api/case/eventNotesDetails/siteControlId');
  }

  dismissReminders(taskPlannerRowKeys: Array<string>, searchRequestParams: any, requestType: ReminderRequestType): Observable<ReminderResult> {

    return this.http.post<ReminderResult>(`${this.baseApiRoute}/dismissReminders`, { taskPlannerRowKeys, searchRequestParams, requestType });
  }

  updateTaskPlannerSearch(saveSearchEntity: SaveSearchEntity, queryKey: Number): Observable<any> {

    return this.http.put(`${this.baseApiRoute}/update/` + queryKey.toString(), saveSearchEntity);

  }

  deferReminders(requestType: ReminderRequestType, taskPlannerRowKeys: Array<string>, holdUntilDate: Date, searchRequestParams: any): Observable<ReminderResult> {

    return this.http.post<ReminderResult>(`${this.baseApiRoute}/deferReminders`, { taskPlannerRowKeys, holdUntilDate, requestType, searchRequestParams });
  }

  getDueDateResponsibility(taskPlannerRowKey: string): Observable<any> {
    return this.http.get<any>(`${this.baseApiRoute}/getDueDateResponsibility/${taskPlannerRowKey}`);
  }

  changeDueDateResponsibility(taskPlannerRowKeys: Array<string>, toNameId: any, searchRequestParams: any): Observable<ReminderResult> {

    return this.http.post<ReminderResult>(`${this.baseApiRoute}/changeDueDateResponsibility`, { taskPlannerRowKeys, toNameId, searchRequestParams });
  }

  forwardReminders(taskPlannerRowKeys: Array<string>, toNameIds: Array<number>, searchRequestParams: any): Observable<ReminderResult> {

    return this.http.post<ReminderResult>(`${this.baseApiRoute}/forwardReminders`, { taskPlannerRowKeys, toNameIds, searchRequestParams });
  }

  getEmailContent(taskPlannerRowKeys: Array<string>, searchRequestParams: any): Observable<Array<ReminderEmailContent>> {

    return this.http.post<Array<ReminderEmailContent>>(`${this.baseApiRoute}/getEmailContent`, { taskPlannerRowKeys, searchRequestParams });
  }

  markAsReadOrUnread(taskPlannerRowKeys: Array<string>, isRead: boolean, searchRequestParams: any): Observable<number> {

    return this.http.post<number>(`${this.baseApiRoute}/readOrUnreadReminders`, { taskPlannerRowKeys, isRead, searchRequestParams });
  }

  hasEmployeeReminder = (dataItem: any): boolean => {
    if (!dataItem.taskPlannerRowKey) {
      return false;
    }
    const employeeReminderId = dataItem.taskPlannerRowKey.split('^')[2];

    return employeeReminderId ? true : false;
  };

  isReminderOrDueDate = (dataItem: any): boolean => {
    if (!dataItem.taskPlannerRowKey) {
      return false;
    }
    const keys = dataItem.taskPlannerRowKey.split('^');
    const reminderType = keys[0];

    return reminderType === TaskPlannerItemType.ReminderOrDueDate;
  };

  isReminderOrAdHoc = (dataItem: any): boolean => {
    if (!dataItem.taskPlannerRowKey) {
      return false;
    }
    const keys = dataItem.taskPlannerRowKey.split('^');
    const reminderType = keys[0];

    return reminderType === TaskPlannerItemType.AdHocDate || this.hasEmployeeReminder(dataItem);
  };

  isShowReminderComments = (dataItem: any): boolean => {
    if (!dataItem.taskPlannerRowKey) {
      return false;
    }

    return this.hasEmployeeReminder(dataItem);
  };

  isAdHoc = (dataItem: any): boolean => {
    if (!dataItem.taskPlannerRowKey) {
      return false;
    }
    const keys = dataItem.taskPlannerRowKey.split('^');
    const reminderType = keys[0];

    return reminderType === TaskPlannerItemType.AdHocDate;
  };

  checkForEventNote = (dataItem: any): boolean => {
    if (!dataItem.taskPlannerRowKey) {
      return false;
    }
    if (this.isReminderOrDueDate(dataItem)) {
      return false;
    }
  };

  getSavedTaskPlannerData(params: any): Observable<SavedTaskPlannerData> {
    const queryKey = +params.queryKey;
    if (queryKey) {
      return this.http.get('api/taskplanner/search/builder/' + queryKey).pipe(
        map((response: SavedTaskPlannerData) => {

          return {
            queryKey,
            queryName: response.queryName,
            formData: response.formData,
            isPublic: response.isPublic
          };
        })
      );
    }

    return of(new SavedTaskPlannerData());
  }

  DeleteSavedSearch(queryKey): any {
    const { baseApiRoute } = SearchTypeConfigProvider.savedConfig;
    if (queryKey) {
      return this.http
        .get(`${baseApiRoute}deleteSavedSearch/${queryKey}`)
        .pipe(
          map((response: any) => {
            return response;
          }));
    }
  }
}
