import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, NgZone, OnDestroy, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/angular';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { AttachmentModalService } from 'common/attachments/attachment-modal.service';
import { AttachmentPopupService } from 'common/attachments/attachments-popup/attachment-popup.service';
import { CommonUtilityService } from 'core/common.utility.service';
import { LocalSettings } from 'core/local-settings';
import { MessageBroker } from 'core/message-broker';
import { AdhocDateService } from 'dates/adhoc-date.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { KotViewForEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { BehaviorSubject, Observable, of, ReplaySubject } from 'rxjs';
import { debounceTime, delay, distinctUntilChanged, map, take, takeUntil, takeWhile } from 'rxjs/operators';
import { SearchHelperService } from 'search/common/search-helper.service';
import { SearchTypeActionMenuProvider } from 'search/common/search-type-action-menus.provider';
import { queryContextKeyEnum, SearchTypeConfig, SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { SearchTypeTaskMenusProvider } from 'search/common/search-type-task-menus.provider';
import { SearchPresentationData } from 'search/presentation/search-presentation.model';
import { SearchPresentationPersistenceService } from 'search/presentation/search-presentation.persistence.service';
import { ContentStatus, ExportContentType } from 'search/results/export.content.model';
import { ReportExportFormat } from 'search/results/report-export.format';
import { SearchResultColumn } from 'search/results/search-results.model';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { ContextMenuParams } from 'shared/component/grid/grouping/ipx-group-item-contextmenu.model';
import { GridHelper } from 'shared/component/grid/ipx-grid-helper';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, scrollableMode } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';
import * as _ from 'underscore';
import { ReminderActionProvider } from '../reminder-action.provider';
import { TaskPlannerPersistenceService } from '../task-planner-persistence.service';
import { Criteria, DateRange, MaintainActions, QueryData, TabData, TaskPlannerViewData, TimePeriod } from '../task-planner.data';
import { TaskPlannerService } from '../task-planner.service';
import { AdHocDateComponent } from './../../../dates/adhoc-date.component';
import { FileDownloadService } from './../../../shared/shared-services/file-download.service';
import { SearchExportService } from './../../results/search-export.service';
import { TaskPlannerSearchHelperService } from './task-planner-search.helper.service';
import { TaskPlannerSerachResultFilterService } from './task-planner.filter.service';

@Component({
  selector: 'ipx-task-planner-search-result',
  templateUrl: './task-planner-search-result.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [
    slideInOutVisible
  ]
})
export class TaskPlannerSearchResultComponent implements OnInit, OnDestroy {
  @Input() viewData: TaskPlannerViewData;
  rowKeyField = 'rowKey';
  selectedRowKey: String | undefined;
  selectedCaseKey: String;
  taskPlannerRowKey: String;
  clickcheck = false;
  gridOptions: IpxGridOptions;
  totalRecords: number;
  queryContextKey: number;
  queryParams: any;
  loaded: boolean;
  defaultProgram: string;
  xmlFilterCriteriaExecuted: string;
  anyColumnLocked = false;
  actions: Array<IpxBulkActionOptions>;
  activeTabSequence: number;
  activeTabTitle: string;
  activeQueryKey: number;
  persistedTab: TabData;
  isPublic: boolean;
  bulkActions: Array<IpxBulkActionOptions>;
  anySelectedSubject = new BehaviorSubject<boolean>(false);
  anySelected$ = this.anySelectedSubject.asObservable();
  taskPlannerKey: string;
  searchConfiguration: SearchTypeConfig;
  exportContentTypeMapper: Array<ExportContentType>;
  dwnlContentSubscription: any;
  dwlContentId$: any;
  bgContentSubscription: any;
  bgContentId$: any;
  bindings: Array<any>;
  exportContentBinding: string;
  destroy$: ReplaySubject<any> = new ReplaySubject<any>(1);
  isRecordFound$ = new BehaviorSubject<boolean>(false);
  notifyReminderCommentChange = false;
  modalRef: BsModalRef;
  taskItems: any;
  contextMenuParams = new ContextMenuParams();
  updateEventNoteIcon = new BehaviorSubject<string>('');
  eventNoteDetailsUpdated$ = this.updateEventNoteIcon.asObservable();
  updateReminderCommentIcon = new BehaviorSubject<string>('');
  updateReminderCommentIcon$ = this.updateReminderCommentIcon.asObservable();
  isSearchFromSearchBuilder = false;
  supressGridRefresh = true;
  unprocessedRowKeys: Array<string>;
  result: Array<any>;
  getFreshResults = false;
  resetFilterParams = true;
  hasAnyChange = true;
  notesHoverText: string;
  commentsHoverText: string;
  openAdhocDisabled: boolean;
  showPreview: boolean;
  expandAction: string;
  dirtyNotesAndComments = new Map<string, boolean>();
  gridHelper = new GridHelper();
  @Input() previousStateParams: {
    name: string,
    params: any
  };
  @ViewChild('resizeDirective') resizeDirective;
  @ViewChild('filterForm', { static: true }) filterForm: NgForm;
  @ViewChild('columnTemplate', { static: true }) template: any;
  @ViewChild('ipxHasNotesAndCommentsColumn', { static: true }) hasNotesCol: TemplateRef<any>;
  @ViewChild('ipxHasReminderCommentColumn', { static: true }) hasReminderCommentCol: TemplateRef<any>;
  @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
  @ViewChild('groupDetailTemplate', { static: true }) groupDetailTemplate: TemplateRef<any>;

  @Output() readonly navigateToEvent = new EventEmitter();

  _resultsGrid: IpxKendoGridComponent;
  activeTab: TabData;
  @ViewChild('resultsGrid', { static: true }) taskPlannerResult: IpxKendoGridComponent;

  @ViewChild('resultsGrid') set resultsGrid(grid: IpxKendoGridComponent) {
    if (grid && !(this._resultsGrid === grid)) {
      if (this._resultsGrid) {
        this._resultsGrid.rowSelectionChanged.unsubscribe();
      }
      this._resultsGrid = grid;
      this.subscribeRowSelectionChange();
    }
  }

  constructor(private readonly localSettings: LocalSettings,
    private readonly cdr: ChangeDetectorRef,
    private readonly taskPlannerService: TaskPlannerService,
    private readonly dateHelper: DateHelper,
    private readonly stateService: StateService,
    public casehelper: SearchHelperService,
    private readonly persistenceService: TaskPlannerPersistenceService,
    private readonly taskPlannerSerachResultFilterService: TaskPlannerSerachResultFilterService,
    private readonly translate: TranslateService,
    private readonly messageBroker: MessageBroker,
    private readonly notificationService: NotificationService,
    private readonly zone: NgZone,
    private readonly searchExportService: SearchExportService,
    private readonly fileDownloadService: FileDownloadService,
    private readonly bsModalRef: BsModalRef,
    private readonly ipxNotificationService: IpxNotificationService,
    readonly taskMenuProvider: SearchTypeTaskMenusProvider,
    private readonly actionMenuProvider: SearchTypeActionMenuProvider,
    private readonly searchHelperService: TaskPlannerSearchHelperService,
    private readonly reminderActionProvider: ReminderActionProvider,
    private readonly commonService: CommonUtilityService,
    private readonly modalService: IpxModalService,
    private readonly adhocDateService: AdhocDateService,
    private readonly attachmentModalService: AttachmentModalService,
    private readonly attachmentPopupService: AttachmentPopupService,
    readonly localDatePipe: LocaleDatePipe,
    private readonly searchPresentationService: SearchPresentationPersistenceService) {
    this.bindings = [];
    this.exportContentBinding = 'export.content';
    this.exportContentTypeMapper = [];
    this.activeTabSequence = null;
    this.contextMenuParams.providerName = 'SearchResultsTaskMenuProvider';
    this.contextMenuParams.contextParams = {
      queryContextKey: queryContextKeyEnum.taskPlannerSearch,
      viewData: null
    };
  }

  ngOnInit(): void {
    this.searchConfiguration = SearchTypeConfigProvider
      .getConfigurationConstants(queryContextKeyEnum.taskPlannerSearch);
    this.subscribeToExportContent();
    this.bgContentId$ = new BehaviorSubject<number>(null);
    this.dwlContentId$ = new BehaviorSubject<number>(null);
    this.subscribeToContents();
    this.actionMenuProvider.initializeContext(null, queryContextKeyEnum.taskPlannerSearch, null, false);
    this.taskMenuProvider.initializeContext(null, queryContextKeyEnum.taskPlannerSearch, false, this.viewData);
    this.taskPlannerService.isCommentDirty$.subscribe(e => {
      if (e && e.rowKey === this.taskPlannerRowKey) {
        this.notifyReminderCommentChange = e.dirty;
      }
    });

    this.subscribeToActionComplete();
    this.taskPlannerService.autoRefreshGrid = this.viewData.autoRefreshGrid;
    if (this.viewData.canViewAttachments) {
      this.watchAttachmentChanges();
    }
    this.contextMenuParams.contextParams.viewData = this.viewData;
  }

  prepareNotesAndCommentsText(dataItem: any): boolean {
    let hasTooltipText = false;
    let reminderCommentRowKey = '';
    let eventNoteRowKey = '';
    this.notesHoverText = '';
    this.commentsHoverText = '';
    const eventNoteUpdated = this.updateEventNoteIcon.getValue() as any;
    const reminderCommentUpdated = this.updateReminderCommentIcon.getValue() as any;
    let reminderCommentLastUpdatedDate = dataItem.lastUpdatedReminderComment !== undefined ? dataItem.lastUpdatedReminderComment : null;
    let eventNoteLastUpdatedDate = dataItem.lastUpdatedEventNoteTimeStamp !== undefined ? dataItem.lastUpdatedEventNoteTimeStamp : null;

    if (eventNoteUpdated !== '') {
      eventNoteRowKey = eventNoteUpdated.taskPlannerRowKey;
      if (eventNoteRowKey === dataItem.taskPlannerRowKey) {
        eventNoteLastUpdatedDate = eventNoteUpdated.lastUpdatedDate !== undefined ? eventNoteUpdated.lastUpdatedDate : null;
        if (!eventNoteLastUpdatedDate) {
          dataItem.eventNotes = eventNoteLastUpdatedDate;
          dataItem.lastUpdatedEventNoteTimeStamp = eventNoteLastUpdatedDate;
        }
      }
    }
    if (reminderCommentUpdated !== '') {
      reminderCommentRowKey = reminderCommentUpdated.taskPlannerRowKey;
      if (reminderCommentRowKey === dataItem.taskPlannerRowKey) {
        reminderCommentLastUpdatedDate = reminderCommentUpdated.lastUpdatedDate;
        if (!reminderCommentLastUpdatedDate) {
          dataItem.reminderComment = reminderCommentLastUpdatedDate;
          dataItem.lastUpdatedReminderComment = reminderCommentLastUpdatedDate;
        }
      }
    }
    hasTooltipText = this.makeNotesEnable(dataItem, eventNoteUpdated, eventNoteRowKey, eventNoteLastUpdatedDate, reminderCommentUpdated, reminderCommentLastUpdatedDate, reminderCommentRowKey);

    return hasTooltipText;
  }

  makeNotesEnable(dataItem: any, eventNoteUpdated: any, eventNoteRowKey: any, eventNoteLastUpdatedDate: any, reminderCommentUpdated: any, reminderCommentLastUpdatedDate: any, reminderCommentRowKey: any): any {
    let hasTooltipText = false;
    if (dataItem.lastUpdatedEventNoteTimeStamp !== undefined || (eventNoteUpdated.lastUpdatedDate !== undefined && eventNoteRowKey === dataItem.taskPlannerRowKey) && dataItem.taskPlannerRowKey.substring(0, 1) !== 'A') {
      if (!this.viewData.maintainEventNotes) {
        this.notesHoverText = this.translate.instant('taskPlanner.eventNoteHover') + '. ';
      }
      this.notesHoverText += this.translate.instant('taskPlanner.eventNoteTimeStamp') + ' ' + this.localDatePipe.transform(eventNoteLastUpdatedDate, 'HH:mm') + '.';
      if (!eventNoteLastUpdatedDate) {
        this.notesHoverText = null;
      } else {
        dataItem.eventNotes = this.notesHoverText;
        hasTooltipText = true;
      }
    } else {
      if (dataItem.eventNotes) {
        this.notesHoverText = dataItem.eventNotes;
        hasTooltipText = true;
      }
    }

    if (this.viewData.showReminderComments && dataItem.lastUpdatedReminderComment !== undefined || (reminderCommentUpdated.lastUpdatedDate !== null && reminderCommentRowKey === dataItem.taskPlannerRowKey)) {
      this.commentsHoverText += this.translate.instant('taskPlanner.reminderCommentsHover') + this.localDatePipe.transform(reminderCommentLastUpdatedDate, 'HH:mm') + '.';
      if (!reminderCommentLastUpdatedDate) {
        this.commentsHoverText = null;
      } else {
        dataItem.reminderComment = this.commentsHoverText;
        hasTooltipText = true;
      }
    } else {
      if (dataItem.reminderComment) {
        this.commentsHoverText = dataItem.reminderComment;
        hasTooltipText = true;
      }
    }

    return hasTooltipText;
  }

  isPicklistSearch(): void {
    if (this.taskPlannerService.taskPlannerStateParam && this.taskPlannerService.taskPlannerStateParam.isPicklistSearch) {
      this.isPublic = false;
      this.getTaskPlannerStateParams();
      this.navigateTo('SearchBuilder');
    }
  }

  private readonly subscribeToActionComplete = () => {

    this.taskPlannerService.onActionComplete$.subscribe(res => {
      if (res && res.reloadGrid && (res.supressAutoRefreshCheck || this.taskPlannerService.autoRefreshGrid)) {
        this.unprocessedRowKeys = res.unprocessedRowKeys;
        if (!this._resultsGrid) {
          return;
        }
        this._resultsGrid.clearSelection();
        this._resultsGrid.search();
        this._resultsGrid.checkChanges();
      } else {
        this.unprocessedRowKeys = [];
      }

      this.cdr.markForCheck();
    });
  };

  togglePreview(showPreview: boolean): void {
    this.showPreview = showPreview;
    this.cdr.markForCheck();
  }

  handelOnEventNoteUpdate = (event: any) => {
    this.updateEventNoteIcon.next(event);
    this.cdr.markForCheck();
  };

  handleOnTaskDetailChange = (event: any) => {
    this.dirtyNotesAndComments.set(event.rowKey, event.isDirty);
  };

  hasAnyNoteOrCommentChanged = (): boolean => {
    if (!this.dirtyNotesAndComments) {
      return false;
    }

    return Array.from(this.dirtyNotesAndComments.values()).find(x => { return x; });
  };

  setQuickFiltersToPristine = (): void => {
    if (this.activeTab.dirtyQuickFilters) {
      this.activeTab.dirtyQuickFilters.clear();
    }
  };

  setQuickFilterDirty = (quickFilterName: string): void => {
    if (!this.activeTab.dirtyQuickFilters) {
      this.activeTab.dirtyQuickFilters = new Map<string, boolean>();
    }
    this.activeTab.dirtyQuickFilters.set(quickFilterName, true);
  };

  isQuickFilterDirty = (quickFilterName: string): boolean => {
    if (!this.activeTab.dirtyQuickFilters) {
      return false;
    }

    return this.activeTab.dirtyQuickFilters.get(quickFilterName);
  };

  handelOnReminderCommentUpdate = (event: any) => {
    this.updateReminderCommentIcon.next(event);
    this.cdr.markForCheck();
  };

  showLoading(): boolean {
    return this.reminderActionProvider.loading;
  }

  ngOnDestroy(): void {
    this.destroy$.next(null);
    this.destroy$.complete();
    const connectionId = this.messageBroker.getConnectionId();
    if (connectionId) {
      this.searchExportService
        .removeAllContents(connectionId).subscribe();
    }
    this.messageBroker.disconnectBindings(this.bindings);
    this.dwnlContentSubscription.unsubscribe();
    this.bgContentSubscription.unsubscribe();
  }

  private readonly subscribeToExportContent = () => {
    this.bindings.push(this.exportContentBinding);
    this.messageBroker.subscribe(this.exportContentBinding, (contents: any) => {
      this.zone.runOutsideAngular(() => {
        this.processContents(contents);
      });
    });

    this.messageBroker.connect();
  };

  subscribeToContents = () => {
    this.dwnlContentSubscription = this.dwlContentId$
      .pipe(debounceTime(100), distinctUntilChanged())
      .subscribe((contentId: number) => {
        if (contentId) {
          this.fileDownloadService.downloadFile('api/export/download/content/' + contentId, null);
        }
      });
    this.bgContentSubscription = this.bgContentId$
      .pipe(debounceTime(100), distinctUntilChanged())
      .subscribe((contentId: number) => {
        if (contentId) {
          const format = _.first(_.filter(this.exportContentTypeMapper, (ect) => {
            return ect.contentId === contentId;
          })).reportFormat;
          this.notificationService.success(this.translate.instant('backgroundContentMessage', {
            value: format
          }), null, 15000);
        }
      });

    this.taskMenuProvider.isMaintainEventFireTaskMenu$.subscribe(result => {
      if (result) {
        this.expandAction = result.maintainActions;
        this.callExpandNotesAndReminder(result.rowIndex, result.taskPlannerRowKey);
      }
    });
  };

  expandNotesAndReminder(dataItem: any): void {
    const data: any = this._resultsGrid.wrapper.data;
    this.expandAction = MaintainActions.notesAndComments.toString();
    const rowIndex = data.data.findIndex(a => a.taskPlannerRowKey === dataItem.taskPlannerRowKey);
    this.callExpandNotesAndReminder(rowIndex, dataItem.taskPlannerRowKey);
  }

  callExpandNotesAndReminder(expandRowIndex: number, taskPlannerRowKey: string): void {
    this.taskPlannerRowKey = taskPlannerRowKey;
    if (this._resultsGrid) {
      if (this.gridOptions.groups.length === 0) {
        this._resultsGrid.expandAll(expandRowIndex);
      } else {
        this.taskMenuProvider.isMaintainEventFireTaskMenuWhenGrouping$.next({ taskPlannerRowKey: this.taskPlannerRowKey, maintainActions: this.expandAction });
      }
      this.gridOptions.detailTemplate = this.gridOptions.groups.length > 0 ? this.groupDetailTemplate : this.detailTemplate;
      this.cdr.markForCheck();
    }
  }

  processContents = (contents: Array<any>) => {
    const downloadables = _.filter(contents, (content) => {
      return content.status === ContentStatus.readyToDownload;
    });
    if (_.any(downloadables)) {
      this.processDownloadableContents(_.pluck(downloadables, 'contentId'));
    }

    const backgroundContents = _.filter(contents, (content) => {
      return content.status === ContentStatus.processedInBackground;
    });
    if (_.any(backgroundContents)) {
      this.processBackgroundContents(_.pluck(backgroundContents, 'contentId'));
    }
  };

  processDownloadableContents = (contentIds: Array<number>) => {
    _.each(contentIds, (contentId: number) => {
      this.dwlContentId$.next(contentId);
    });
  };

  processBackgroundContents = (contentIds: Array<number>) => {
    _.each(contentIds, (contentId: number) => {
      this.bgContentId$.next(contentId);
    });
  };

  initializeTab(tab: QueryData, supressGridRefresh: boolean): void {
    this.supressGridRefresh = supressGridRefresh;
    this.isPublic = tab.isPublic;
    const defaultQueryKey = tab.key;
    this.activeTabSequence = tab.tabSequence;
    this.activeTabTitle = tab.searchName;
    this.queryContextKey = queryContextKeyEnum.taskPlannerSearch;
    this.activeQueryKey = defaultQueryKey;

    this.persistedTab = null;

    this.activeTab = this.persistenceService.getTabBySequence(this.activeTabSequence);
    if (!this.isTabDataPersisted()) {
      const defaultCriteria: any = { searchRequest: { anySearch: { operator: 2, value: this.viewData.q } } };
      this.activeTab.filter = this.viewData.filter ? this.viewData.filter : defaultCriteria;
      this.activeTab.timePeriods = [...this.viewData.timePeriods];
      this.activeTab.showFilterArea = this.localSettings.keys.taskPlanner.showFilterArea.getSession;
      this.activeTab.selectedPeriodId = this.activeTab.timePeriods[0].id;
      this.activeTab.savedSearch = {
        query: new QueryData(),
        criteria: new Criteria()
      };
      this.activeTab.savedSearch.criteria.dateFilter = new DateRange();
      this.activeTab.defaultTimePeriods = [];
      this.setPreStateParamData(defaultQueryKey);
    } else {
      this.hasAnyChange = false;
      this.queryParams = this.activeTab.queryParams;
      this.result = this.activeTab.results;
      this.loadGridData();
    }
    if (this.viewData.maintainTaskPlannerSearch && this.viewData.maintainTaskPlannerSearchPermission.insert) {
      this.isPicklistSearch();
    }
    this.initMenuActions();
    this.taskPlannerService.showKeepOnTopNotes();
    this.cdr.markForCheck();
  }

  isTabDataPersisted(): boolean {
    if (this.taskPlannerService.isCustomSearch()
      || !this.activeTab.results
      || (this.taskPlannerService.previousStateParam
        && this.taskPlannerService.previousStateParam.searchBuilder)) { return false; }

    return this.activeTab.isPersisted;
  }

  presistTaskPlannerData(): void {
    this.persistenceService.changedTabSeq$.subscribe(res => {
      if (res.clicked && this.activeTabSequence === res.activeTab) {
        this.activeTab.isPersisted = true;
        this.activeTab.results = this.result;
        this.activeTab.queryParams = this.queryParams;
        this.getFreshResults = false;
        this.resetFilterParams = false;
        this.saveActiveTab();
      }
    });
  }

  saveActiveTab(): void {
    this.activeTab.isPersisted = true;
    this.persistenceService.saveActiveTab(this.activeTabSequence, this.activeTab);
  }

  navigateTo(value): void {
    this.saveActiveTab();
    this.navigateToEvent.emit(value);
  }

  updateTabState(query: QueryData): void {
    this.activeTabSequence = query.tabSequence;
    if (!this.activeTab.searchName && query.searchName) {
      this.activeTab.selectedColumns = null;
      this.searchPresentationService.setSearchPresentationData(null, query.tabSequence.toString());
    }
    this.activeTab = {
      queryKey: query.key,
      description: query.description,
      presentationId: query.presentationId,
      sequence: query.tabSequence,
      selectedColumns: this.activeTab.selectedColumns,
      searchName: query.searchName,
      results: this.result,
      canRevert: false
    };
    this.persistenceService.saveActiveTab(this.activeTabSequence, this.activeTab);
  }

  private getDefaultTimePeriod(sequence: number): any {
    const r = _.first(_.filter(this.activeTab.defaultTimePeriods, (tp: any) => {
      return tp.sequence === sequence;
    }));

    return r ? r.defaultTimePeriod : this.activeTab.selectedPeriodId;
  }

  private setPreStateParamData(defaultQueryKey: any): void {
    const preStateParam = this.taskPlannerService.previousStateParam;
    this.activeTab.selectedColumns = null;
    let queryKey = defaultQueryKey;
    if (this.taskPlannerService.isCustomSearch()) {
      this.isSearchFromSearchBuilder = true;
      this.activeQueryKey = preStateParam.queryKey;
      this.activeTab.queryKey = null;
      this.activeTab.searchName = '';
      this.activeTab.selectedColumns = preStateParam.selectedColumns;
      this.activeTab.builderFormData = preStateParam.formData;
      this.activeTab.savedSearch = preStateParam.savedSearch ? preStateParam.savedSearch : this.activeTab.savedSearch;
      this.activeTab.filter = preStateParam.filterCriteria;
      this.activeTab.selectedPeriodId = preStateParam.timePeriod ? preStateParam.timePeriod : this.getDefaultTimePeriod(this.activeTabSequence).id;
      queryKey = null;
      this.taskPlannerService.previousStateParam.searchBuilder = false;
    }
    this.getSavedSearchQueryData(queryKey, this.activeTab.filter);
  }

  private getSavedSearchQueryData(queryKey: number, filterCriteria): void {
    this.taskPlannerService.getSavedSearchQuery(queryKey, filterCriteria).subscribe(data => {
      this.supressGridRefresh = true;
      if (data.criteria) {
        this.activeTab.savedSearch = data;
        this.activeTab.selectedPeriodId = data.criteria.timePeriodId ? data.criteria.timePeriodId : this.activeTab.selectedPeriodId ? this.activeTab.selectedPeriodId : 1;
        const from = data.criteria.dateFilter.from;
        const to = data.criteria.dateFilter.to;
        const sequence = this.activeTabSequence;
        this.activeTab.defaultTimePeriods.push({
          sequence,
          defaultTimePeriod: {
            from,
            to,
            id: data.criteria.timePeriodId
          }
        });
        this.activeTab.savedSearch.criteria.dateFilter.from = from ? this.dateHelper.convertForDatePicker(from) : null;
        this.activeTab.savedSearch.criteria.dateFilter.to = to ? this.dateHelper.convertForDatePicker(to) : null;

        this.activeTab.names = data.criteria.belongsTo.names;
        this.activeTab.nameGroups = data.criteria.belongsTo.nameGroups;
      }
      this.manageHorizontalScrollBar();
      this.cdr.detectChanges();
      this.loadGridData();
    });
  }

  private readonly loadGridData = () => {
    this.loaded = false;
    this.taskPlannerService.getColumns$(this.activeQueryKey,
      this.activeTab.selectedColumns,
      this.queryContextKey).subscribe(data => {
        const options = this.buildGridOptions(data);
        this.gridOptions = options;
        this.loaded = true;
        this.cdr.markForCheck();
      });
  };

  onSavedSearchChange(query: QueryData): void {
    this.taskPlannerService.isSavedSearchChangeEvent = true;
    this.activeTab.canRevert = false;
    this.setQuickFiltersToPristine();
    this.taskPlannerService.rowSelectedForKot.next({ id: null, type: KotViewForEnum.Case });
    this.activeQueryKey = query.key;
    this.updateTabState(query);
    this.initializeTab(query, true);
  }

  revertQuickFilters(): void {
    this.onSavedSearchChange({
      searchName: this.activeTab.searchName,
      tabSequence: this.activeTab.sequence,
      isPublic: this.isPublic,
      key: this.activeTab.queryKey
    });
  }

  hasBooleanValue = (data: any): Boolean => {
    if (data == null || data === undefined) {
      return false;
    }
    switch (data.toString()) {
      case 'true':
      case 'false':

        return true;
      default:
        return false;
    }
  };

  getEncodeLinkData = (column: any, data: any): string => {
    let urlParams = {};
    switch (column.columnItemId) {
      case 'Owner':
        urlParams = { nameKey: data.ownerKey };
        break;
      case 'StaffMember':
        urlParams = { nameKey: data.staffMemberKey };
        break;
      case 'Signatory':
        urlParams = { nameKey: data.signatoryKey };
        break;
      case 'DueDateResponsibility':
        urlParams = { nameKey: data.dueDateResponsibilityNameKey };
        break;
      case 'ReminderFor':
        urlParams = { nameKey: data.reminderForNameKey };
        break;
      case 'Instructor':
        urlParams = { nameKey: data.instructorKey };
        break;
      default: break;
    }

    return 'api/search/redirect?linkData=' +
      encodeURIComponent(JSON.stringify(urlParams));
  };

  initMenuActions(): void {
    this.bulkActions = [{
      ...new IpxBulkActionOptions(),
      id: 'export-to',
      icon: 'cpa-icon cpa-icon-check-in',
      text$: this.exportMenuText$,
      enabled$: this.isRecordFound$.asObservable().pipe(map((result) => result)),
      items: [{
        ...new IpxBulkActionOptions(),
        id: 'export-excel',
        text: 'bulkactionsmenu.excel',
        enabled: true,
        click: () => {
          this.validateExportLimit(ReportExportFormat.Excel);
        }
      }, {
        ...new IpxBulkActionOptions(),
        id: 'export-word',
        icon: 'cpa-icon cpa-icon-file-word-o',
        text: 'bulkactionsmenu.word',
        enabled: true,
        click: () => {
          this.validateExportLimit(ReportExportFormat.Word);
        }
      }, {
        ...new IpxBulkActionOptions(),
        id: 'export-pdf',
        icon: 'cpa-icon cpa-icon-file-pdf-o',
        text: 'bulkactionsmenu.pdf',
        enabled: true,
        click: () => {
          this.validateExportLimit(ReportExportFormat.PDF);
        }
      }]
    }];
    const actionMenuItems = this.actionMenuProvider.getConfigurationActionMenuItems(this.queryContextKey, this.viewData, false);
    if (actionMenuItems) {
      this.bulkActions = actionMenuItems.concat(this.bulkActions);
    }

  }
  exportMenuText = new BehaviorSubject<string>(this.translate.instant('bulkactionsmenu.exportAllTo'));
  exportMenuText$ = this.exportMenuText.asObservable();

  subscribeRowSelectionChange = () => {
    this._resultsGrid.rowSelectionChanged.subscribe((event) => {
      const exportMenuText = event.rowSelection.length > 0
        ? 'bulkactionsmenu.exportSelectedTo'
        : 'bulkactionsmenu.exportAllTo';
      this.exportMenuText.next(exportMenuText);

      const anySelected = event.rowSelection.length > 0;
      const dismissReminder = this.bulkActions.find(x => x.id === 'dismiss-reminders');
      if (dismissReminder) {
        dismissReminder.enabled = anySelected;
      }
      const finalise = this.bulkActions.find(x => x.id === 'finalise');
      if (finalise) {
        finalise.enabled = anySelected;
      }
      const deferReminder = this.bulkActions.find(x => x.id === 'defer-reminders');
      if (deferReminder) {
        deferReminder.enabled = anySelected;
      }
      const markAsReadUnRead = this.bulkActions.find(x => x.id === 'mark-as-read-unread');
      if (markAsReadUnRead) {
        markAsReadUnRead.enabled = anySelected;
      }
      const dueDateResponsibility = this.bulkActions.find(x => x.id === 'change-due-date-responsibility');
      if (dueDateResponsibility) {
        dueDateResponsibility.enabled = anySelected;
      }
      const forwardReminders = this.bulkActions.find(x => x.id === 'forward-reminders');
      if (forwardReminders) {
        forwardReminders.enabled = anySelected;
      }
    });
  };

  clearSelection(): void {
    this._resultsGrid.clearSelection();
  }

  displayWarning = (exportFormat: ReportExportFormat) => {
    this.notificationService.confirm({
      title: this.translate.instant('modal.warning.title'),
      message: this.commonService.formatString(this.translate.instant('modal.warning.message'), this.viewData.exportLimit.toString()),
      cancel: this.translate.instant('modal.warning.cancel'),
      continue: this.translate.instant('modal.warning.proceed')
    }).then(() => {
      this.export(exportFormat);
    }, () => { return; });
  };

  validateExportLimit = (exportFormat: ReportExportFormat) => {
    const exportLimitExceeded = this.isExportLimitExceeded();
    if (exportLimitExceeded) {
      this.displayWarning(exportFormat);
    } else {
      this.export(exportFormat);
    }
  };

  isExportLimitExceeded = (): Boolean => {
    const exportLimit = this.viewData.exportLimit;
    let totalSelectedRows: number;
    totalSelectedRows = this._resultsGrid.getRowSelectionParams().isAllPageSelect || this._resultsGrid.getRowSelectionParams().rowSelection.length === 0 ? this.totalRecords.valueOf() - this._resultsGrid.getRowSelectionParams().allDeSelectedItems.length : this._resultsGrid.getRowSelectionParams().allSelectedItems.length;
    if (totalSelectedRows > exportLimit) {

      return true;
    }

    return false;
  };

  export(format: ReportExportFormat): void {
    const exportFormat = ReportExportFormat[format].toString();
    let exportFilter: any = {};
    const queryParams = this.queryParams;
    queryParams.skip = null;
    queryParams.take = null;
    const searchName = this.activeQueryKey ? this.activeTab.savedSearch.query.searchName : 'Task List';

    exportFilter = this.taskPlannerSerachResultFilterService.getFilter(this._resultsGrid.getRowSelectionParams().isAllPageSelect, this._resultsGrid.getRowSelectionParams().allSelectedItems,
      this._resultsGrid.getRowSelectionParams().allDeSelectedItems, this.rowKeyField, this.activeTab.filter, this.searchConfiguration);
    this.searchExportService
      .generateContentId(this.messageBroker.getConnectionId())
      .pipe(take(1))
      .subscribe((contentId: number) => {
        this.notificationService
          .success(this.translate.instant('exportSubmitMessage', {
            value: exportFormat
          }));
        this.exportContentTypeMapper.push({
          contentId,
          reportFormat: ReportExportFormat[exportFormat].toString()
        });
        this.searchExportService.export(
          exportFilter,
          queryParams,
          searchName,
          this.activeQueryKey,
          this.queryContextKey,
          false,
          this.activeTab.selectedColumns,
          format,
          contentId,
          exportFilter.deselectedIds
        ).pipe(take(1),
          takeUntil(this.destroy$))
          .subscribe((r) => {
            if (this.activeTab.filter.searchRequest.rowKeys) {
              delete this.activeTab.filter.searchRequest.rowKeys;
            }
          });
      });
  }

  private readonly buildGridOptions = (columnsData: Array<SearchResultColumn>): IpxGridOptions => {
    const columns = this.buildColumns(columnsData);
    const pageSizes = [10, 20, 50, 100];
    const pageSizeSetting = this.localSettings.keys.caseSearch.pageSize.default;
    if (pageSizeSetting.getLocal > _.last(pageSizes)) {
      this.gridHelper.storePageSizeToLocalStorage(_.last(pageSizes), pageSizeSetting);
    }
    const options: IpxGridOptions = {
      sortable: true,
      pageable: {
        pageSizeSetting,
        pageSizes
      },
      scrollableOptions: this.anyColumnLocked ? { mode: scrollableMode.scrollable } : { mode: scrollableMode.none },
      groupable: true,
      groups: this.buildGroups(columnsData),
      filterable: true,
      reorderable: true,
      showContextMenu: true,
      selectable: {
        mode: 'multiple'
      },
      customRowClass: (context) => {
        let returnValue = '';
        if (context.dataItem && this.rowKeyField && context.dataItem[this.rowKeyField] === this.selectedRowKey) {
          returnValue += 'k-state-selected selected';
        }
        if (this.isRowUnprocessed(context.dataItem.taskPlannerRowKey)) {
          returnValue += ' error';
        }
        if (!context.dataItem.isRead) {
          returnValue += ' text-bold';
        }

        return returnValue;
      },
      read$: (queryParams: GridQueryParameters) => {
        this.taskPlannerService.isSavedSearchChangeEvent = true;
        if (!this.persistenceService.isTabPersisted(this.activeTabSequence) || this.hasAnyChange) {
          this.queryParams = this.removeValueFromSort(queryParams);
          this.getFreshResults = true;
          this.resetFilterParams = true;
        }
        this.searchHelperService.setSearchCriteria(this.activeTab, this.queryParams, this.activeQueryKey, this.isSearchFromSearchBuilder);
        this.hasAnyChange = true;

        return this.getContextData$()
          .pipe(map((res: any) => {
            _.each(res.data, (r: any) => {
              if (_.isEmpty(r.isEditable)) {
                r.isEditable = this.taskMenuProvider.hasTaskMenuItems(r);
              }
            });
            this.isSearchFromSearchBuilder = false;

            return res;
          }));
      },
      filterMetaData$: (column) => {
        const filterData = this.activeTab.filter;

        return this.taskPlannerService
          .getColumnFilterData(filterData, (column.field.endsWith('.value') ? column.field.replace('.value', '') : column.field), this.queryParams, this.activeQueryKey, this.activeTab.selectedColumns, this.queryContextKey);
      },
      columns,
      bulkActions: this.bulkActions,
      selectedRecords: {
        rows: {
          rowKeyField: this.rowKeyField,
          selectedKeys: []
        }
      },
      detailTemplate: this.detailTemplate,
      detailTemplateShowCondition: (dataItem: any): boolean => (dataItem.taskPlannerRowKey && dataItem.taskPlannerRowKey.substring(0, 1) !== 'A') || (dataItem.showReminderComments && this.viewData.showReminderComments),
      groupDetailTemplate: this.groupDetailTemplate,
      onClearSelection: () => {
        this.viewData.rowKey = '';
      },
      onDataBound: (data: any) => {
        this.taskPlannerService.taskPlannerRowKey.next(null);
        this.taskPlannerService.rowSelectedForKot.next({ id: null, type: KotViewForEnum.Case });
        if (data.data) {
          data.data.length ? this.isRecordFound$.next(true) : this.isRecordFound$.next(false);
          this._resultsGrid.focusRow(-1);
          if (this.persistenceService.isTabPersisted(this.activeTabSequence)) {
            this._resultsGrid.wrapper.filter = { filters: [], logic: 'and' };
            _.forEach(this.queryParams.filters, (filter: any) => {
              const persistedFilter = [];
              persistedFilter.push(filter);
              this._resultsGrid.wrapper.filter.filters.push({ filters: persistedFilter, logic: 'and' });
            });
            this._resultsGrid.wrapper.sort = [{ field: this.queryParams.sortBy, dir: this.queryParams.sortDir }];
            this.cdr.detectChanges();

          }
        }
        this.supressGridRefresh = false;
      }
    };

    return options;
  };

  onDateRangeChange = (event, dateField: string) => {
    if (!this.hasGridLoaded()) {
      return;
    }

    if (this.activeTab.selectedPeriodId !== 1) {
      const selectedPeriod = _.first(_.filter(this.activeTab.timePeriods, (tp: TimePeriod) => {
        return tp.id === this.activeTab.selectedPeriodId;
      }));

      const selectedDate = event ? this.dateHelper.toLocal(event) : null;
      const defaultFromDate = selectedPeriod.fromDate ? this.dateHelper.toLocal(selectedPeriod.fromDate) : null;
      const defaultToDate = selectedPeriod.toDate ? this.dateHelper.toLocal(selectedPeriod.toDate) : null;
      if ((dateField === 'from' && defaultFromDate !== selectedDate) ||
        (dateField === 'to' && defaultToDate !== selectedDate)) {
        this.activeTab.selectedPeriodId = 1;
        this.setQuickFilterDirty('timePeriod');
      }
    }

    this.clearSelection();
    const defaultTimePeriod = this.getDefaultTimePeriod(this.activeTabSequence);
    if (defaultTimePeriod && this.activeTab.selectedPeriodId === defaultTimePeriod.id) {
      if (dateField === 'to') {
        defaultTimePeriod.toDate = event;
      } else {
        defaultTimePeriod.fromDate = event;
      }
    }
    if (!this.taskPlannerService.isSavedSearchChangeEvent) {
      this.activeTab.canRevert = this.activeTab.queryKey ? true : false;
      this.setQuickFilterDirty(dateField);
    }
  };

  onNameChanged = () => {
    this.clearSelection();
    this.manageHorizontalScrollBar();
    if (!this.taskPlannerService.isSavedSearchChangeEvent) {
      this.activeTab.canRevert = this.activeTab.queryKey ? true : false;
      this.setQuickFilterDirty('nameKey');
    }

  };

  manageHorizontalScrollBar = _.debounce(() => {
    const multiselect = document.querySelector<HTMLDivElement>('.multiselect');
    const height = ((multiselect.scrollHeight - 26) * -1) - 170;
    this.resizeDirective.resizeHeaderHeight = this.activeTab.showFilterArea ? height : -148;

    if (typeof (Event) === 'function') {
      window.dispatchEvent(new Event('resize'));
    } else {
      const resizeEvent = window.document.createEvent('UIEvents');
      resizeEvent.initEvent('resize', true, false);
      window.dispatchEvent(resizeEvent);
    }
  }
    , 150);

  onNameGroupChanged = () => {
    this.clearSelection();
    this.manageHorizontalScrollBar();
    if (!this.taskPlannerService.isSavedSearchChangeEvent) {
      this.activeTab.canRevert = this.activeTab.queryKey ? true : false;
      this.setQuickFilterDirty('nameGroups');
    }
  };

  private readonly preventGridRefresh = (): boolean => {
    return this.supressGridRefresh
      || this.isSearchFromSearchBuilder
      || !this.hasGridLoaded()
      || !this.filterForm.valid;
  };

  refreshGrid = (force = false) => {

    if (this.preventGridRefresh() && !force) {

      return;
    }

    this.setQuickFiltersToPristine();
    this.unprocessedRowKeys = [];
    this.updateEventNoteIcon.next('');
    this.updateReminderCommentIcon.next('');
    this.clearSelection();
    this.gridOptions._search();
    this.attachmentPopupService.clearCache();
    this.cdr.markForCheck();
  };

  dataItemClicked = (event: any) => {
    const selected = event;
    this.selectedCaseKey = selected && selected.caseKey != null ? selected.caseKey.toString() : null;
    this.taskPlannerRowKey = selected && selected.taskPlannerRowKey != null ? selected.taskPlannerRowKey.toString() : null;
    this.taskPlannerService.rowSelectedForKot.next({ id: this.selectedCaseKey, type: KotViewForEnum.Case });
    this.taskPlannerService.rowSelected.next(this.selectedCaseKey);
    this.taskPlannerService.taskPlannerRowKey.next(this.taskPlannerRowKey);
  };

  getCssClassForDueDate(column: any, dataItem: any): string {
    if (column.columnItemId === 'DueDate' || column.columnItemId === 'ReminderDate') {
      if (dataItem.isDueDateToday) {
        return 'text-black-bold text-nowrap';
      } else if (dataItem.isDueDatePast) {
        return 'text-danger text-black-bold text-nowrap';
      }
    }

    return 'text-nowrap';
  }

  isRowUnprocessed(rowKey: string): boolean {
    return this.unprocessedRowKeys && _.any(this.unprocessedRowKeys, key => {
      return key === rowKey;
    });
  }

  private readonly getContextData$ = (): Observable<any> => {

    if (this.persistenceService.getTabBySequence(this.activeTabSequence) && this.persistenceService.isTabPersisted(this.activeTabSequence) && !this.getFreshResults) {
      this.getFreshResults = false;
      const persistedData = this.persistenceService.getTabBySequence(this.activeTabSequence);
      this.queryParams = persistedData.queryParams;

      return this.convertToGridData(of(persistedData.results).pipe(delay(200)));
    }

    return this.convertToGridData(
      this.taskPlannerService.getSavedSearch$(
        this.activeQueryKey,
        this.queryParams,
        this.queryContextKey,
        this.searchHelperService.getFilter(),
        this.activeTab.selectedColumns
      ).pipe(map(data => {
        this.result = data;

        return data;
      })));
  };

  toggleFilterArea = () => {
    this.clearSelection();
    this.activeTab.showFilterArea = !this.activeTab.showFilterArea;
    this.localSettings.keys.taskPlanner.showFilterArea.setSession(this.activeTab.showFilterArea);
    this.manageHorizontalScrollBar();
  };

  private readonly convertToGridData = (results: Observable<any>): Observable<any> => {
    return results.pipe(map(data => {
      this.totalRecords = data.totalRows;
      this.taskPlannerService.isSavedSearchChangeEvent = false;

      return {
        data: data.rows,
        pagination: { total: data.totalRows }
      };
    }
    ));
  };

  private readonly removeValueFromSort = (queryParams: GridQueryParameters): GridQueryParameters => {
    if (queryParams.sortBy && queryParams.sortBy.endsWith('.value')) {
      queryParams.sortBy = queryParams.sortBy.replace('.value', '');
    }

    return queryParams;
  };

  private buildColumns(selectedColumns: Array<SearchResultColumn>): any {
    if (selectedColumns && selectedColumns.length > 0) {
      const columns = [];
      this.anyColumnLocked = _.any(selectedColumns, (c) => c.isColumnFreezed) &&
        _.any(selectedColumns, (c) => !c.isColumnFreezed);
      if (this.anyColumnLocked) {
        this.casehelper.computeColumnsWidth(selectedColumns, 55);
      }
      columns.push({
        width: 40,
        title: '',
        field: 'lastUpdatedEventNoteTimeStamp',
        fixed: true,
        sortable: false,
        menu: false,
        template: this.hasNotesCol
      });
      if (this.viewData.canViewAttachments) {
        columns.push({
          title: '',
          field: 'attachmentCount',
          width: 40,
          template: true,
          sortable: false,
          fixed: true
        });
      }
      selectedColumns.forEach(c => {
        columns.push({
          title: c.title,
          template: this.template,
          templateExternalContext: {
            id: c.id,
            isHyperlink: c.isHyperlink,
            format: c.format,
            linkType: c.linkType,
            linkArgs: c.linkArgs,
            decimalPlaces: c.decimalPlaces,
            currencyCodeColumnName: c.currencyCodeColumnName,
            columnItemId: c.columnItemId
          },
          sortable: true,
          field: c.isHyperlink ? c.id + '.value' : c.id,
          columnItemId: c.columnItemId,
          filter: c.filterable,
          locked: c.isColumnFreezed,
          width: this.anyColumnLocked ? c.width : 'auto'
        });
      });

      return columns;
    }

    return [];
  }

  onMenuItemSelected = (menuEventDataItem: any): void => {
    menuEventDataItem.event.item.action(menuEventDataItem.dataItem, menuEventDataItem.event);
  };

  displayTaskItems = (dataItem: any): void => {
    this.taskMenuProvider.queryContextKey = queryContextKeyEnum.taskPlannerSearch;
    this.taskItems = this.taskMenuProvider.getConfigurationTaskMenuItems(dataItem);
    if (dataItem.caseKey) {
      const webLink = _.find(this.taskMenuProvider._baseTasks, (t: any) => {
        return t.menu && t.menu.id === 'caseWebLinks';
      });
      if (webLink) {
        this.taskMenuProvider.subscribeCaseWebLinks(dataItem, webLink);
      }
    }
  };

  onTimePeriodChange = (value: any): void => {
    if (!this.hasGridLoaded()) {
      return;
    }
    this.clearSelection();
    if (!this.taskPlannerService.isSavedSearchChangeEvent) {
      this.setQuickFilterDirty('timePeriod');
    }
    this.activeTab.selectedPeriodId = value;
    if (value === 1) {
      const r = _.first(_.filter(this.activeTab.defaultTimePeriods, (tp: any) => {
        return tp.sequence === this.activeTabSequence;
      }));

      this.activeTab.savedSearch.criteria.dateFilter.from = this.dateHelper.convertForDatePicker(r.defaultTimePeriod.from);
      this.activeTab.savedSearch.criteria.dateFilter.to = this.dateHelper.convertForDatePicker(r.defaultTimePeriod.to);

      return;
    }
    const newPeriod = _.first(_.filter(this.activeTab.timePeriods, (tp: TimePeriod) => {
      return tp.id === value;
    }));

    this.activeTab.savedSearch.criteria.dateFilter.from = newPeriod.fromDate ? this.dateHelper.convertForDatePicker(newPeriod.fromDate) : null;
    this.activeTab.savedSearch.criteria.dateFilter.to = newPeriod.toDate ? this.dateHelper.convertForDatePicker(newPeriod.toDate) : null;
    this.supressGridRefresh = true;
  };

  hasGridLoaded = (): Boolean => {
    return this.loaded && this.gridOptions ? true : false;
  };

  buildGroups(selectedColumns: Array<SearchResultColumn>): any {
    const groupColumns = _.sortBy(_.filter(selectedColumns, (sc: SearchResultColumn) => {
      return sc.groupBySortOrder && !_.isUndefined(sc.groupBySortOrder);
    }), 'groupBySortOrder');

    return _.map(groupColumns, (gc: SearchResultColumn) => {
      return {
        dir: gc.groupBySortDirection === 'descending' ? 'desc' : 'asc',
        field: gc.isHyperlink ? gc.id + '.value' : gc.id
      };
    });
  }

  getTaskPlannerStateParams = (): any => {
    this.taskPlannerService.taskPlannerStateParam = {
      filterCriteria: { ...this.activeTab.filter },
      formData: { ...this.activeTab.builderFormData },
      names: this.activeTab.names,
      nameGroups: this.activeTab.nameGroups,
      timePeriod: this.activeTab.selectedPeriodId,
      selectedColumns: this.activeTab.selectedColumns,
      activeTabSeq: this.activeTabSequence,
      searchName: this.activeTab.searchName,
      queryKey: this.activeQueryKey,
      maintainPublicSearch: this.viewData.maintainPublicSearch,
      maintainTaskPlannerSearch: this.viewData.maintainTaskPlannerSearch,
      maintainTaskPlannerSearchPermission: this.viewData.maintainTaskPlannerSearchPermission,
      isPublic: this.isPublic
    };

    return this.taskPlannerService.taskPlannerStateParam;
  };

  openPresentation = (): any => {
    this.getTaskPlannerStateParams();
    this.saveActiveTab();
    this.stateService.go('searchpresentation', {
      filter: { filterCriteria: this.activeTab.filter, formData: this.activeTab.builderFormData },
      activeTabSeq: this.activeTabSequence,
      queryKey: this.activeQueryKey,
      isPublic: this.isPublic,
      queryName: this.activeTab.searchName,
      queryContextKey: queryContextKeyEnum.taskPlannerSearch
    });
  };

  openAdHocDate = (): any => {
    this.openAdhocDisabled = true;
    this.adhocDateService.viewData().subscribe(r => {
      const initialState = {
        viewData: r
      };
      this.modalRef = this.modalService.openModal(AdHocDateComponent, {
        backdrop: 'static',
        class: 'modal-lg',
        initialState
      });
      this.modalRef.content.onClose$.pipe(takeWhile(() => !!this.modalRef)).subscribe(value => {
        if (value) {
          this.openAdhocDisabled = false;
        }
      });
    });
  };

  onExpand(event: any): void {
    this.expandAction = null;
    this.taskPlannerRowKey = event.dataItem.taskPlannerRowKey;
    this.gridOptions.detailTemplate = this.gridOptions.groups.length > 0 ? this.groupDetailTemplate : this.detailTemplate;
  }

  onCollapse(event: any): void {
    this.expandAction = null;
    if (this.clickcheck) {
      this.clickcheck = false;

      return;
    }
    if (this.notifyReminderCommentChange) {
      event.prevented = true;
      this.modalRef = this.ipxNotificationService.openDiscardModal();
      this.modalRef.content.confirmed$.subscribe(() => {
        const collapseElement = this._resultsGrid.wrapper.wrapper.nativeElement.querySelector('.k-hierarchy-cell .k-minus');
        if (collapseElement) {
          this.clickcheck = true;
          collapseElement.click();
          this.taskPlannerService.isCommentDirty$.next({
            rowKey: this.taskPlannerRowKey,
            dirty: false
          });
        }
        this.bsModalRef.hide();
      });
    }

  }

  openAttachmentWindow = (dataItem: any): void => {
    this.attachmentModalService.displayAttachmentModal('case', dataItem.caseKey, {
      eventKey: dataItem.eventKey,
      eventCycle: dataItem.eventCycle,
      actionKey: dataItem.actionKey
    });
  };

  private readonly watchAttachmentChanges = (): void => {
    this.attachmentModalService.attachmentsModified
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        if (this.taskPlannerService.autoRefreshGrid) {
          this.refreshGrid(true);
          this.cdr.markForCheck();
        }
      });
  };
}
