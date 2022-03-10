import {
    ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, NgZone, OnDestroy, OnInit, Renderer2, TemplateRef, ViewChild
} from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService, Transition, TransitionService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { CaseNavigationService } from 'cases/core/case-navigation.service';
import { CommonUtilityService } from 'core/common.utility.service';
import { LocalSettings } from 'core/local-settings';
import { MessageBroker } from 'core/message-broker';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { BehaviorSubject, Observable } from 'rxjs';
import { debounceTime, distinctUntilChanged, map } from 'rxjs/operators';
import { BillSearchProvider, BillSearchTaskMenuItemOperationType } from 'search/bill-search/bill-search.provider';
import { CaseSearchService } from 'search/case/case-search.service';
import { SearchTypeActionMenuProvider } from 'search/common/search-type-action-menus.provider';
import {
    queryContextKeyEnum,
    SearchTypeConfig, SearchTypeConfigProvider
} from 'search/common/search-type-config.provider';
import { SearchTypeTaskMenusProvider } from 'search/common/search-type-task-menus.provider';
import { SelectedColumn } from 'search/presentation/search-presentation.model';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { ContextMenuParams } from 'shared/component/grid/grouping/ipx-group-item-contextmenu.model';
import { GridHelper } from 'shared/component/grid/ipx-grid-helper';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, scrollableMode } from 'shared/component/grid/ipx-kendo-grid.component';
import * as _ from 'underscore';
import { DateService } from '../../ajs-upgraded-providers/date-service.provider';
import { SearchHelperService } from '../common/search-helper.service';
import { FileDownloadService } from './../../shared/shared-services/file-download.service';
import { ContentStatus, ExportContentType } from './export.content.model';
import { ReportExportFormat } from './report-export.format';
import { SearchExportService } from './search-export.service';
import { SearchResultPermissionsEvaluator } from './search-result-permissions-evaluator';
import {
    SearchResultEntryPoint,
    SearchResultsViewData,
    StateParams
} from './search-results.data';
import { CaseSerachResultFilterService } from './search-results.filter.service';
import { SearchResultColumn } from './search-results.model';
import { SearchResultsService } from './search-results.service';

@Component({
    selector: 'search-results',
    templateUrl: './search-results.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class SearchResultsComponent implements OnInit, OnDestroy {
    @Input() viewData: SearchResultsViewData;
    @Input() previousState: StateParams;
    @ViewChild('columnTemplate', { static: true }) template: any;
    @ViewChild('hybridResultDiv') hybridResulElementRef: ElementRef;
    @ViewChild('groupDetailTemplate', { static: true }) groupDetailTemplate: TemplateRef<any>;
    anyColumnLocked = false;
    _resultsGrid: IpxKendoGridComponent;
    @ViewChild('resultsGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
            this.subscribeRowSelectionChange();
        }
    }
    gridOptions: IpxGridOptions;
    loaded: boolean;
    totalRecords?: Number;
    queryParams: any;
    searchResultEntryPoint: SearchResultEntryPoint;
    filter: any;
    rowKeyField: string;
    dateFormat: any;
    searchTerm: any;
    queryKey?: number;
    isSavedSearch: any;
    showPreview: Boolean;
    showWebLink: boolean;
    selectedRowKey: String | undefined;
    hasOffices: Boolean;
    hasFileLocation: Boolean;
    isExternal: Boolean;
    actions: Array<IpxBulkActionOptions>;
    defaultProgram: string;
    selectedColumns: Array<SelectedColumn>;
    queryContextKey: number;
    isHosted = false;
    searchConfiguration: SearchTypeConfig;
    pageTitle: string;
    xmlFilterCriteriaExecuted: string;
    taskItems: any;
    permissions: any;
    exportFormat: ReportExportFormat;
    bindings: Array<string>;
    dwnlContentSubscription: any;
    bgContentSubscription: any;
    bgContentId$;
    dwlContentId$;
    exportContentBinding: string;
    exportContentTypeMapper: Array<ExportContentType>;
    isRefreshClickedInHosted: Boolean = false;
    contextMenuParams = new ContextMenuParams();
    gridHelper = new GridHelper();

    constructor(
        private readonly rootScopeService: RootScopeService,
        private readonly service: SearchResultsService,
        private readonly dateService: DateService,
        private readonly stateService: StateService,
        private readonly localSettings: LocalSettings,
        readonly searchExportService: SearchExportService,
        private readonly transitionService: TransitionService,
        private readonly navigationService: CaseNavigationService,
        private readonly notificationService: NotificationService,
        private readonly cdRef: ChangeDetectorRef,
        public casehelper: SearchHelperService,
        private readonly translate: TranslateService,
        private readonly windowParentMessagingService: WindowParentMessagingService,
        private readonly caseService: CaseSearchService,
        readonly actionMenuProvider: SearchTypeActionMenuProvider,
        private readonly caseSerachResultFilterService: CaseSerachResultFilterService,
        readonly taskMenuProvider: SearchTypeTaskMenusProvider,
        private readonly searchResultPermissionsEvaluator: SearchResultPermissionsEvaluator,
        private readonly fileDownloadService: FileDownloadService,
        private readonly zone: NgZone,
        private readonly messageBroker: MessageBroker,
        private readonly renderer: Renderer2,
        private readonly commonService: CommonUtilityService,
        private readonly billSearchProvider: BillSearchProvider) {
        this.bindings = [];
        this.exportContentBinding = 'export.content';
        this.exportContentTypeMapper = [];
    }

    ngOnInit(): any {
        this.isHosted = this.rootScopeService.isHosted ? true : false;
        if (this.previousState && this.previousState.name === 'bulk-edit') {
            const bulkUpdateData = this.localSettings.keys.bulkUpdate.data.getSession;
            if (bulkUpdateData && this.stateService.params.checkPersistedData) {
                this.viewData.rowKey = undefined;
                this.previousState = bulkUpdateData.previousState;
                this.localSettings.keys.bulkUpdate.data.setSession(null);
            } else {
                this.previousState = null;
            }
        }

        this.queryContextKey = this.viewData.queryContext;
        this.billSearchProvider.initializeContext(this.viewData.permissions, this.isHosted);
        this.initializeManusContext(this.viewData.permissions);
        this.createConfigurations(this.queryContextKey);
        this.hasOffices = this.viewData.hasOffices;
        this.hasFileLocation = this.viewData.hasFileLocation;
        this.isExternal = this.viewData.isExternal;
        this.dateFormat = this.dateService.dateFormat;
        this.setEntryPoint(this.viewData);
        this.isSavedSearch = !this.viewData.searchQueryKey && this.viewData.queryKey;
        this.queryKey = this.viewData.queryKey;
        this.searchTerm = this.queryKey ? this.viewData.queryName : this.viewData.q;
        const defaultCriteria: any = {};
        defaultCriteria.searchRequest = [{ anySearch: { operator: 2, value: this.viewData.q } }];
        this.filter = this.viewData.filter ? this.viewData.filter : defaultCriteria;
        this.queryParams = { skip: 0, take: 200 };
        this.selectedColumns = this.viewData.selectedColumns;
        this.loadData();
        this.subscribeToExportContent();
        this.bgContentId$ = new BehaviorSubject<number>(null);
        this.dwlContentId$ = new BehaviorSubject<number>(null);
        this.subscribeToContents();
        this.subscribeToActionComplete();
    }

    private readonly initializeManusContext = (permissions: any): void => {
        this.permissions = permissions;
        this.searchResultPermissionsEvaluator.initializeContext(this.permissions, this.queryContextKey, this.isHosted);
        this.taskMenuProvider.initializeContext(this.permissions, this.queryContextKey, this.isHosted, this.viewData);
        this.actionMenuProvider.initializeContext(this.permissions, this.queryContextKey, this.exportContentTypeMapper, this.isHosted);
        if (this.permissions) {
            this.showWebLink = this.permissions.canShowLinkforInprotechWeb === true;
        }
        this.contextMenuParams.providerName = 'SearchResultsTaskMenuProvider';
        this.contextMenuParams.contextParams = {
            permissions: this.permissions,
            queryContextKey: this.queryContextKey,
            isHosted: this.isHosted,
            viewData: this.viewData
        };
    };

    private readonly subscribeToActionComplete = () => {

        this.casehelper.onActionComplete$.subscribe(res => {
            if (res && res.reloadGrid) {
                this._resultsGrid.clearSelection();
                this._resultsGrid.search();
                this._resultsGrid.checkChanges();
            }
            this.cdRef.markForCheck();
        });
    };

    createConfigurations = (key: Number) => {
        this.searchConfiguration = SearchTypeConfigProvider.getConfigurationConstants(key);
        this.pageTitle = this.viewData.backgroundProcessResultTitle || this.searchConfiguration.pageTitle;
        this.rowKeyField = this.searchConfiguration.rowKeyField;
        this.actions = this.initializeMenuActions();
    };

    subscribeRowSelectionChange = () => {
        this._resultsGrid.rowSelectionChanged.subscribe((event) => {
            const exportExcelMenuText = event.rowSelection.length > 0
                ? 'bulkactionsmenu.ExportSelectedToExcel'
                : 'bulkactionsmenu.ExportAllToExcel';
            this.exportExcelMenuText.next(exportExcelMenuText);
            const exportWordMenuText = event.rowSelection.length > 0
                ? 'bulkactionsmenu.ExportSelectedToWord'
                : 'bulkactionsmenu.ExportAllToWord';
            this.exportWordMenuText.next(exportWordMenuText);
            const exportPdfMenuText = event.rowSelection.length > 0
                ? 'bulkactionsmenu.ExportSelectedToPdf'
                : 'bulkactionsmenu.ExportAllToPdf';
            this.exportPdfMenuText.next(exportPdfMenuText);
            const exportCpaXmlMenuText = event.rowSelection.length > 0
                ? 'bulkactionsmenu.ExportSelectedCpaXml'
                : 'bulkactionsmenu.ExportAllCpaXml';
            this.exportCpaXmlMenuText.next(exportCpaXmlMenuText);
            const bulkUpdate = this.actions.find(x => x.id === 'case-bulk-update');
            if (bulkUpdate) {
                bulkUpdate.enabled = event.rowSelection.length > 0;
            }
            const bulkPolicing = this.actions.find(x => x.id === 'case-bulk-policing');
            if (bulkPolicing) {
                bulkPolicing.enabled = event.rowSelection.length > 0;
            }
            const batchEvent = this.actions.find(x => x.id === 'batch-event-update');
            if (batchEvent) {
                batchEvent.enabled = event.rowSelection.length > 0;
            }
            const caseDataComparison = this.actions.find(x => x.id === 'case-data-comparison');
            if (caseDataComparison) {
                caseDataComparison.enabled = event.rowSelection.length > 0;
            }
            const sanityCheck = this.actions.find(x => x.id === 'sanity-check');
            if (sanityCheck) {
                sanityCheck.enabled = event.rowSelection.length > 0;
            }
            const addToCaselist = this.actions.find(x => x.id === 'add-to-caselist');
            if (addToCaselist) {
                addToCaselist.enabled = event.rowSelection.length > 0;
            }
            const globalNameChange = this.actions.find(x => x.id === 'global-name-change');
            if (globalNameChange) {
                globalNameChange.enabled = event.rowSelection.length > 0;
            }

            const createSingleBill = this.actions.find(x => x.id === 'create-single-bill');
            if (createSingleBill) {
                createSingleBill.enabled = event.rowSelection.length > 0;
            }
            const createMultipleBill = this.actions.find(x => x.id === 'create-multiple-bill');
            if (createMultipleBill) {
                createMultipleBill.enabled = event.rowSelection.length > 0;
            }

            const billingWorksheet = this.actions.find(x => x.id === 'create-billing-worksheet');
            if (billingWorksheet) {
                billingWorksheet.enabled = event.rowSelection.length > 0;
            }

            const billingWorksheetext = this.actions.find(x => x.id === 'create-billing-worksheet-extended');
            if (billingWorksheetext) {
                billingWorksheetext.enabled = event.rowSelection.length > 0;
            }
        });
    };

    loadData = () => {
        this.loaded = false;
        this.service.getColumns$(this.queryKey, this.selectedColumns, this.viewData.presentationType, this.queryContextKey).subscribe(data => {
            const options = this.buildGridOptions(data);
            this.gridOptions = options;
            this.cdRef.detectChanges();
            this.setSearchResultsData();
            this.loaded = true;
            this.cdRef.detectChanges();
        });
        this.handleBrowserBack();
        if (this.viewData.programs) {
            this.defaultProgram = this.viewData.programs.find((pg) => pg.isDefault).id;
        }
    };

    onReload = (data: any) => {
        this.queryKey = data.queryKey;
        this.selectedColumns = data.selectedColumns;
        this.createConfigurations(this.queryContextKey);
        this.setEntryPoint(this.viewData);
        this.loadData();
        this.subscribeRowSelectionChange();
        this.cdRef.detectChanges();
    };

    handleBrowserBack = () => {
        // executes only when previous state is saved case search
        if (this.previousState && this.previousState.params.queryKey) {
            this.transitionService.onBefore({ to: 'casesearch', from: 'search-results' }, (trans: Transition) => {
                const params = trans.params();
                if (params.queryKey && !params.canEdit && this.previousState.params.queryKey === params.queryKey) {
                    const newParams = { ...this.previousState.params, returnFromCaseSearchResults: true };

                    return this.stateService.target(this.previousState.name, newParams);
                }
            });
        }
    };

    encodeLinkData = (data: any) =>
        'api/search/redirect?linkData=' +
        encodeURIComponent(JSON.stringify(data));

    exportExcelMenuText = new BehaviorSubject<string>(this.translate.instant('bulkactionsmenu.ExportAllToExcel'));
    exportExcelMenuText$ = this.exportExcelMenuText.asObservable();
    exportWordMenuText = new BehaviorSubject<string>(this.translate.instant('bulkactionsmenu.ExportAllToWord'));
    exportWordMenuText$ = this.exportWordMenuText.asObservable();
    exportPdfMenuText = new BehaviorSubject<string>(this.translate.instant('bulkactionsmenu.ExportAllToPdf'));
    exportPdfMenuText$ = this.exportPdfMenuText.asObservable();
    exportCpaXmlMenuText = new BehaviorSubject<string>(this.translate.instant('bulkactionsmenu.ExportAllCpaXml'));
    exportCpaXmlMenuText$ = this.exportCpaXmlMenuText.asObservable();

    private initializeMenuActions(): Array<IpxBulkActionOptions> {
        const menuItems: Array<IpxBulkActionOptions> = [{
            ...new IpxBulkActionOptions(),
            id: 'export-excel',
            icon: 'cpa-icon cpa-icon-file-excel-o',
            text$: this.exportExcelMenuText$,
            enabled: true,
            click: () => {
                this.validateExportLimit(ReportExportFormat.Excel);
            }
        }, {
            ...new IpxBulkActionOptions(),
            id: 'export-word',
            icon: 'cpa-icon cpa-icon-file-word-o',
            text$: this.exportWordMenuText$,
            enabled: true,
            click: () => {
                this.validateExportLimit(ReportExportFormat.Word);
            }
        }, {
            ...new IpxBulkActionOptions(),
            id: 'export-pdf',
            icon: 'cpa-icon cpa-icon-file-pdf-o',
            text$: this.exportPdfMenuText$,
            enabled: true,
            click: () => {
                this.validateExportLimit(ReportExportFormat.PDF);
            }
        }];

        if (this.searchConfiguration.searchType === 'case') {
            menuItems.push({
                ...new IpxBulkActionOptions(),
                id: 'case-cpa-xml-import',
                icon: 'cpa-icon cpa-icon-file-code-o',
                text$: this.exportCpaXmlMenuText$,
                enabled: true,
                click: this.cpaXmlImport
            });
        }

        return menuItems.concat(this.actionMenuProvider.getConfigurationActionMenuItems(this.queryContextKey, this.viewData, this.isHosted));
    }

    onMenuItemSelected = (menuEventDataItem: any): void => {
        menuEventDataItem.event.item.action(menuEventDataItem.dataItem, menuEventDataItem.event);
    };

    initializeTaskItems = (dataItem: any): void => {
        this.taskItems = this.taskMenuProvider.getConfigurationTaskMenuItems(dataItem);
    };

    openPresentation = (): void => {
        this.windowParentMessagingService.postLifeCycleMessage({ action: 'onSearchPresentationModal', target: 'searchResultHost' }, () => {
            this.stateService.go('searchpresentation', {
                queryKey: this.viewData.queryKey,
                filter: this.viewData.filter,
                queryName: this.viewData.queryName,
                q: this.viewData.q,
                selectedColumns: this.selectedColumns,
                queryContextKey: this.queryContextKey
            });
        });
    };

    export = (exportFormat: ReportExportFormat) => {
        this.exportFormat = exportFormat;
        if (this.viewData.presentationType) {
            this.searchExportService.exportGlobalChangeResultToExcel(
                this.viewData.globalProcessKey,
                this.viewData.presentationType,
                this.queryParams,
                this.viewData.backgroundProcessResultTitle,
                exportFormat);

            return;
        }

        let exportFilter: any = {};
        const queryParams = this.queryParams;
        queryParams.skip = null;
        queryParams.take = null;
        if (this.searchConfiguration.allowExportFiltering) {
            exportFilter = this.caseSerachResultFilterService.getFilter(this._resultsGrid.getRowSelectionParams().isAllPageSelect, this._resultsGrid.getRowSelectionParams().allSelectedItems,
                this._resultsGrid.getRowSelectionParams().allDeSelectedItems, this.rowKeyField, this.filter, this.searchConfiguration);
            exportFilter.dueDateFilter = this.filter.dueDateFilter;
        }

        const forceConstructXmlCriteria =
            this.searchResultEntryPoint === SearchResultEntryPoint.SavedSearchBuilder
            && this.viewData.filter.searchRequest && this.viewData.filter.dueDateFilter != null;

        const searchName: any =
            this.searchResultEntryPoint ===
                SearchResultEntryPoint.NewSearchBuilder ||
                this.searchResultEntryPoint === SearchResultEntryPoint.QuickCaseSearch
                ? null
                : this.searchTerm;

        this.searchExportService
            .generateContentId(this.messageBroker.getConnectionId())
            .subscribe((contentId: number) => {
                this.notificationService
                    .success(this.translate.instant('exportSubmitMessage', {
                        value: ReportExportFormat[this.exportFormat].toString()
                    }));
                this.exportContentTypeMapper.push({
                    contentId,
                    reportFormat: ReportExportFormat[this.exportFormat].toString()
                });
                this.searchExportService.export(
                    exportFilter,
                    queryParams,
                    searchName,
                    this.queryKey,
                    this.queryContextKey,
                    forceConstructXmlCriteria,
                    this.selectedColumns,
                    exportFormat,
                    contentId,
                    exportFilter.deselectedIds
                ).subscribe();
            });
    };

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
    };

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

    cpaXmlImport = () => {
        /* why is this case specific requirement implemented in a generic component */
        let exportFilter: any = {};
        const allSelectedItems = this._resultsGrid.getRowSelectionParams().allSelectedItems;
        const allDeSelectedItems = this._resultsGrid.getRowSelectionParams().allDeSelectedItems;
        if (allSelectedItems.length > 0 || allDeSelectedItems.length > 0) {
            exportFilter = this.caseSerachResultFilterService.getFilter(this._resultsGrid.getRowSelectionParams().isAllPageSelect, allSelectedItems,
                allDeSelectedItems, this.rowKeyField, this.filter, this.searchConfiguration);
            exportFilter.dueDateFilter = this.filter.dueDateFilter;
        } else {
            exportFilter = _.clone(this.filter);
        }

        this.searchExportService.exportToCpaXml(exportFilter, this.queryContextKey)
            .subscribe(() => {
                this.notificationService.success('successfulCpaXmlExport');
            });
    };

    setEntryPoint(viewData: any): void {
        if (viewData.searchQueryKey && viewData.filter) {
            this.searchResultEntryPoint = viewData.queryKey
                ? SearchResultEntryPoint.SavedSearchBuilder
                : SearchResultEntryPoint.NewSearchBuilder;
        } else {
            this.searchResultEntryPoint =
                !viewData.queryKey
                    ? SearchResultEntryPoint.QuickCaseSearch
                    : SearchResultEntryPoint.ExecuteSavedSearch;
        }
    }

    refresh = (): void => {
        if (this.isHosted) {
            this.renderer.addClass(this.hybridResulElementRef.nativeElement, 'refreshHostedResult');
            this.isRefreshClickedInHosted = true;
        }
        this.gridOptions._refresh();
    };

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

    private readonly buildGridOptions = (columnsData: Array<SearchResultColumn>): IpxGridOptions => {
        this.selectedRowKey = null;
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
            groupable: true,
            groupDetailTemplate: this.groupDetailTemplate,
            enableTaskMenu: this.searchResultPermissionsEvaluator.checkForAtleaseOneTaskMenuPermission(),
            groups: this.buildGroups(columnsData),
            filterable: true,
            reorderable: true,
            showContextMenu: this.searchResultPermissionsEvaluator.showContextMenu(),
            customRowClass: (context) => {
                let returnValue = '';
                if (context.dataItem && this.rowKeyField && context.dataItem[this.rowKeyField] === this.selectedRowKey) {
                    returnValue += 'k-state-selected selected';
                }

                return returnValue;
            },
            onDataItemCheckboxSelection: this.searchConfiguration.customCheckboxSelection,
            selectable: this.searchConfiguration.selectableSetting,
            scrollableOptions: this.anyColumnLocked ? { mode: scrollableMode.scrollable } : { mode: scrollableMode.none },
            bulkActions: this.actions,
            read$: (queryParams: GridQueryParameters) => {
                this.queryParams = this.removeValueFromSort(queryParams);

                return this.getContextData$();
            },
            filterMetaData$: (column) => {
                const filterData = this.filter;

                return this.service
                    .getColumnFilterData(filterData, (column.field.endsWith('.value') ? column.field.replace('.value', '') : column.field), this.queryParams, this.queryKey, this.selectedColumns, this.queryContextKey);
            },
            columns,
            selectedRecords: {
                rows: {
                    rowKeyField: 'rowKey',
                    selectedKeys: []
                }
            },
            onClearSelection: () => {
                this.viewData.rowKey = '';
                this.caseSerachResultFilterService.persistSelectedItems([]);
            },
            onDataBound: (data: any) => {
                if (data.data && data.data.length > 0 && this.viewData.rowKey) {
                    if (this.stateService.params.checkPersistedData) {
                        const selectedItems = this.caseSerachResultFilterService.getPersistedSelectedItems();
                        if (selectedItems.length > 0) {
                            this._resultsGrid.getRowSelectionParams().allSelectedItems = selectedItems;
                        }
                    }
                    const rowKeys = this.viewData.rowKey.toString().split(',');
                    if (rowKeys.length > 0) {
                        this.setSearchResultsData();
                        const selectedRow = data.data.find(r => r.rowKey === rowKeys[0]);
                        this.selectedRowKey = selectedRow && this.rowKeyField ? selectedRow[this.rowKeyField] : null;
                        if (selectedRow) {
                            const index = data.data.findIndex(r => r.rowKey === rowKeys[0]);
                            this._resultsGrid.focusRow(index, true);
                        }
                        _.each(data.data, (row: any) => {
                            row.selected = !this.viewData.clearSelection && this.isSelectedRow(rowKeys, row.rowKey);
                        });
                        this._resultsGrid.checkChanged();
                    }
                } else {
                    this.selectedRowKey = null;
                }
                if (this.queryContextKey === queryContextKeyEnum.billSearch && data.data && data.data.length > 0) {
                    _.each(data.data, (row: any) => {
                        row.isEditable = this.billSearchProvider.canAccessTask(row, BillSearchTaskMenuItemOperationType.deleteDraftBill)
                            || this.billSearchProvider.canAccessTask(row, BillSearchTaskMenuItemOperationType.reverse)
                            || this.billSearchProvider.canAccessTask(row, BillSearchTaskMenuItemOperationType.credit);
                    });
                }
                this.caseSerachResultFilterService.persistSelectedItems([]);
                this.scrollTop();
                this.showPreview = this.localSettings.keys.caseSearch.showPreview.getLocal;
            }
        };

        return options;
    };

    getHighlightedRowKey = (): any => {
        if (!this.selectedRowKey || !this._resultsGrid) {
            return null;
        }
        const data = this._resultsGrid.getCurrentData();
        const row = _.find(data, (t: any) => {
            return t[this.rowKeyField] === this.selectedRowKey;
        });

        if (row) {
            return row.rowKey;
        }

        return null;
    };

    getContextData$ = (): Observable<any> => {
        let results: Observable<any>;
        let ret: boolean;

        if (this.viewData.presentationType && this.searchConfiguration.searchType === 'case') {
            results = this.caseService.getGlobalCaseChangeResults$(this.viewData.globalProcessKey, this.viewData.presentationType, this.queryParams, this.queryContextKey);
            ret = true;
        } else if (this.filter && (this.filter instanceof String || typeof this.filter === 'string')) {
            results = this.queryKey
                ? this.service.getEditedSavedSearch$(this.queryKey, this.filter, this.queryParams, this.selectedColumns, this.queryContextKey)
                : this.service.getSearch$(this.filter, this.queryParams, this.selectedColumns, this.queryContextKey);
            ret = true;
        } else if (this.isSavedSearch) {
            results = this.viewData.filter
                ? this.service.getEditedSavedSearch$(this.queryKey, this.filter, this.queryParams, this.selectedColumns, this.queryContextKey)
                : this.service.getSavedSearch$(this.queryKey, this.queryParams, this.selectedColumns, this.queryContextKey);
            ret = true;
        } else if (!this.isSavedSearch && this.queryKey) {
            results = (this.viewData.hasDueDatePresentation || (this.viewData.filter && !this.viewData.filter.searchRequest && this.viewData.filter.dueDateFilter != null) && this.searchConfiguration.searchType === 'case')
                ? this.caseService.getDueDateSavedSearch$(this.queryKey, this.filter, this.queryParams, this.queryContextKey)
                : this.caseService.getCaseEditedSavedSearch$(this.queryKey, this.filter, this.queryParams, this.selectedColumns, this.queryContextKey);
            ret = true;
        }

        if (!ret) {
            results = this.service.getSearch$(this.filter, this.queryParams, this.selectedColumns, this.queryContextKey);
        }

        return this.convertToGridData(results);
    };

    private readonly convertToGridData = (results: Observable<any>): Observable<any> => {

        return results.pipe(map(data => {
            this.totalRecords = data.totalRows;
            this.xmlFilterCriteriaExecuted = data.xmlCriteriaExecuted;
            this.viewData.xmlCriteriaExecuted = data.xmlCriteriaExecuted;
            this.windowParentMessagingService.postLifeCycleMessage({
                action: 'onChange', target: 'searchResultHost', payload: {
                    totalRecords: this.totalRecords,
                    searchTerm: this.searchTerm,
                    xmlFilterCriteria: this.xmlFilterCriteriaExecuted
                }
            });
            if (this.isRefreshClickedInHosted) {
                this.isRefreshClickedInHosted = false;
                this.renderer.removeClass(this.hybridResulElementRef.nativeElement, 'refreshHostedResult');
            }

            return {
                data: data.rows,
                pagination: { total: data.totalRows }
            };
        }
        ));
    };

    private readonly setSearchResultsData = () => {
        const rowKey = this.viewData.rowKey;
        if (rowKey && rowKey.toString().split(',').length > 0) {
            const rowKeys = rowKey.toString().split(',');
            this.navigationService.tempReturnNextRecordSetFromCache();
            this.gridOptions.selectedRecords = {
                page: this.navigationService.getCurrentPageIndex(rowKeys[0]),
                rows: {
                    rowKeyField: 'rowKey',
                    selectedKeys: rowKeys
                }
            };
        }
    };

    private readonly isSelectedRow = (selectedRowKeys: Array<string>, rowKey: string) => {

        return _.some(selectedRowKeys, (key: string) => {
            return key === rowKey;
        });
    };

    onPageChanged = (data: any) => {
        if (data.take !== data.oldPageSize) {
            this.navigationService.clearLoadedData();
        }
    };

    dataItemClicked = event => {
        const selected = event;
        this.selectedRowKey = selected && this.rowKeyField ? selected[this.rowKeyField] : undefined;
    };

    setStoreOnToggle(event: Event): void {
        this.localSettings.keys.caseSearch.showPreview.setLocal(event);
    }

    buildColumns(selectedColumns: Array<SearchResultColumn>): any {
        if (selectedColumns && selectedColumns.length > 0) {
            const columns = [];
            this.anyColumnLocked = _.any(selectedColumns, (c) => c.isColumnFreezed) &&
                _.any(selectedColumns, (c) => !c.isColumnFreezed);
            if (this.anyColumnLocked) {
                const gridElementWidth = document.querySelector('ipx-sticky-header').parentElement.clientWidth - (this.actions ? 55 : 35);
                this.casehelper.computeColumnsWidth(selectedColumns, gridElementWidth);
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
                        currencyCodeColumnName: c.currencyCodeColumnName
                    },
                    sortable: true,
                    field: c.isHyperlink ? c.id + '.value' : c.id,
                    filter: c.filterable,
                    locked: c.isColumnFreezed,
                    width: this.anyColumnLocked ? c.width : 'auto',
                    headerClass: this.isHosted && (c.format === 'Currency' || c.format === 'Local Currency') ? 'k-header-right-aligned' : ''
                });
            });

            return columns;
        }

        return [];
    }

    close = () => {
        if (this.previousState) {
            let params = {};
            if (this.previousState.name === 'casesearch') {
                params = { ...this.previousState.params, returnFromCaseSearchResults: true };
            } else if (this.previousState.name === 'searchpresentation') {
                params = {
                    queryKey: this.viewData.queryKey,
                    filter: this.viewData.filter,
                    queryName: this.viewData.queryName,
                    selectedColumns: this.selectedColumns,
                    queryContextKey: this.queryContextKey
                };
            } else {
                window.history.go(-1);
            }
            this.stateService.go(this.previousState.name, params);
        } else {
            window.history.go(-1);
        }
    };

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

    removeValueFromSort = (queryParams: GridQueryParameters): GridQueryParameters => {
        if (queryParams.sortBy && queryParams.sortBy.endsWith('.value')) {
            queryParams.sortBy = queryParams.sortBy.replace('.value', '');
        }

        return queryParams;
    };

    ngOnDestroy(): void {
        this.service.rowSelected = new BehaviorSubject(null);
        this.searchExportService
            .removeAllContents(this.messageBroker.getConnectionId()).subscribe();
        this.messageBroker.disconnectBindings(this.bindings);
        this.dwnlContentSubscription.unsubscribe();
        this.bgContentSubscription.unsubscribe();
    }

    scrollTop(): void {
        const container = document.querySelector('.table-container');
        container.scrollLeft = 0;
        container.scrollTop = 0;
    }

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

    getFlagStyle(linkType: string): {
        [key: string]: string;
    } {
        let colorCode = '';

        switch (linkType) {
            case 'RestrictedCasesIcon':
                colorCode = '#ff0000';
                break;
            default: break;
        }

        return {
            color: colorCode
        };
    }

    getToolTipMessage(linkType: string): String {
        let toolTip = '';

        switch (linkType) {
            case 'RestrictedCasesIcon':
                toolTip = this.translate.instant('SearchColumns.billSearch.hasRestrictedCases');
                break;
            default: break;
        }

        return toolTip;
    }
}