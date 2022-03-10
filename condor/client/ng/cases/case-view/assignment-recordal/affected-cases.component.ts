
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, EventEmitter, OnChanges, OnInit, Output, Renderer2, SimpleChanges, ViewChild } from '@angular/core';
import { FormGroup, NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import * as angular from 'angular';
import { LocalSettings } from 'core/local-settings';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { Observable } from 'rxjs';
import { map, takeUntil, takeWhile } from 'rxjs/operators';
import { SearchHelperService } from 'search/common/search-helper.service';
import { SearchResultColumn } from 'search/results/search-results.model';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent, scrollableMode } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { MaintenanceTopicContract } from '../base/case-view-topics.base.component';
import { CaseDetailService } from '../case-detail.service';
import { caseViewTopicTitles } from '../case-view-topic-titles';
import { AddAffectedCaseComponent } from './add-affected-case/add-affected-case.component';
import { AffectedCaseStatusEnum, BulkOperationType, RecordalRequestType } from './affected-cases.model';
import { AffectedCasesService } from './affected-cases.service';
import { AffectedCasesFilterModel } from './model/filter.model';
import { RecordalStepsComponent } from './recordal-steps/recordal-steps.component';
import { RequestRecordalComponent } from './request-recordal/request-recordal.component';
import { AffectedCasesSetAgentComponent } from './set-agent/affected-cases-set-agent.component';

@Component({
    selector: 'ipx-caseview-affected-cases',
    templateUrl: './affected-cases.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class AffectedCasesComponent implements OnInit, OnChanges, MaintenanceTopicContract {
    @ViewChild('columnTemplate', { static: false }) template: any;
    _resultsGrid: IpxKendoGridComponent;
    @ViewChild('ipxKendoGridRef') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
            this.subscribeRowSelectionChange();
        }
    }
    @ViewChild('ngForm', { static: true }) form: NgForm;
    @Output() readonly pageChanged = new EventEmitter();
    topic: Topic;
    gridOptions: IpxGridOptions;
    isHosted = false;
    canMaintainCase = false;
    anyColumnLocked = false;
    totalRecords?: Number;
    showWebLink: boolean;
    caseKey: number;
    setStepStatus: Boolean;
    showFilter = false;
    formGroup: FormGroup;
    filterParams: AffectedCasesFilterModel;
    actions: Array<IpxBulkActionOptions>;
    stepColumns: any;
    recordalStepsTooltip: string;
    cannotDeleteAffectedCaseKeys: Array<string> = [];
    isLoading = false;
    selectedCases: any;
    modalRef: any;
    editedRows = [];
    constructor(readonly localSettings: LocalSettings,
        private readonly cdRef: ChangeDetectorRef,
        private readonly rootScopeService: RootScopeService,
        private readonly service: AffectedCasesService,
        public casehelper: SearchHelperService,
        private readonly modalService: IpxModalService,
        private readonly caseDetailService: CaseDetailService,
        private readonly renderer: Renderer2,
        readonly elementRef: ElementRef,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly notificationService: NotificationService,
        private readonly translate: TranslateService,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService) { }

    ngOnChanges(changes: SimpleChanges): void {
        this.cdRef.detectChanges();
    }

    ngOnInit(): void {
        this.isHosted = this.rootScopeService.isHosted;
        if (this.topic.setErrors) {
            this.topic.setErrors(false);
        }
        this.showWebLink = (this.topic.params as AffectedCasesTopicParams).showWebLink;
        this.canMaintainCase = this.isHosted && this.topic.params.viewData.canMaintainCase;
        this.topic.hasChanges = false;
        this.caseKey = this.topic.params.viewData.caseKey;
        this.loadData();
        this.actions = this.initializeMenuActions();
        this.caseDetailService.resetChanges$.subscribe((val: boolean) => {
            if (val) {
                this.resetForms();
            }
        });
        this.handleShortcuts();
    }

    loadData = () => {
        this.service.getColumns$(this.caseKey).subscribe(data => {
            this.gridOptions = this.buildGridOptions(data);
            this.setStatusColumn();
            this.stepColumns = _.filter(this.gridOptions.columns, (col) => {
                return col.field.startsWith('step');
            });
            this.cdRef.detectChanges();
        });
    };

    private readonly subscribeRowSelectionChange = () => {
        this._resultsGrid.rowSelectionChanged.subscribe((event) => {
            this.actions.forEach(action => action.enabled = event.rowSelection.length > 0);
        });
    };

    private initializeMenuActions(): Array<IpxBulkActionOptions> {
        const menuItems: Array<IpxBulkActionOptions> = [{
            ...new IpxBulkActionOptions(),
            id: 'request-recordal',
            icon: 'cpa-icon cpa-icon-share',
            text: 'bulkactionsmenu.requestRecordal',
            enabled: false,
            click: this.requestRecordal
        }, {
            ...new IpxBulkActionOptions(),
            id: 'apply-recordal',
            icon: 'cpa-icon cpa-icon-check-circle',
            text: 'bulkactionsmenu.applyRecordal',
            enabled: false,
            click: this.applyRecordal
        }, {
            ...new IpxBulkActionOptions(),
            id: 'reject-recordal',
            icon: 'cpa-icon cpa-icon-ban',
            text: 'bulkactionsmenu.rejectRecordal',
            enabled: false,
            click: this.rejectRecordal
        }, {
            ...new IpxBulkActionOptions(),
            id: 'delete-affectedCases',
            icon: 'cpa-icon cpa-icon-trash',
            text: 'bulkactionsmenu.delete',
            enabled: false,
            click: this.deleteAffectedCases
        }, {
            ...new IpxBulkActionOptions(),
            id: 'set-agent',
            icon: 'cpa-icon cpa-icon-user',
            text: 'bulkactionsmenu.setAffectedCaseAgent',
            enabled: false,
            click: this.setAffectedCaseAgent
        }, {
            ...new IpxBulkActionOptions(),
            id: 'clear-affectedCaseAgent',
            icon: 'cpa-icon cpa-icon-user-slash',
            text: 'bulkactionsmenu.clearAffectedCaseAgent',
            enabled: false,
            click: this.clearAffectedCaseAgent
        }];

        return menuItems;
    }

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.ADD, (): void => { if (this.isHosted) { this.openAddAffectedCases(); } }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.ADD])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key) && this.isHosted) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    requestRecordal = (resultsGrid: IpxKendoGridComponent) => {
        this.performRecordalOperations(resultsGrid, RecordalRequestType.Request);
    };

    rejectRecordal = (resultsGrid: IpxKendoGridComponent) => {
        this.performRecordalOperations(resultsGrid, RecordalRequestType.Reject);
    };

    applyRecordal = (resultsGrid: IpxKendoGridComponent) => {
        this.performRecordalOperations(resultsGrid, RecordalRequestType.Apply);
    };

    performRecordalOperations = (resultGrid: IpxKendoGridComponent, operationType: RecordalRequestType) => {
        const selectedRowKeys = _.pluck(resultGrid.getRowSelectionParams().allSelectedItems, 'rowKey');
        const deselectedRowKeys = _.pluck(resultGrid.getRowSelectionParams().allDeSelectedItems, 'rowKey');
        const isAllPageSelect = resultGrid.getRowSelectionParams().isAllPageSelect;
        this.modalRef = this.modalService.openModal(RequestRecordalComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                selectedRowKeys,
                mainCaseId: this.caseKey,
                showWebLink: this.showWebLink,
                isAllPageSelect,
                filterParams: this.filterParams,
                deselectedRows: deselectedRowKeys,
                requestType: operationType
            }
        });

        this.modalRef.content.onClose$.subscribe(value => {
            if (value) {
                if (operationType === RecordalRequestType.Apply) {
                    this.notificationService.info({
                        title: 'caseview.affectedCases.requestRecordal.applyTitle',
                        message: 'caseview.affectedCases.applyRecordalRequest'
                    });
                } else {
                    if (value === 'success') {
                        let request = 'caseview.affectedCases.requestRecordal.requestTitle';
                        if (operationType === RecordalRequestType.Reject) {
                            request = 'caseview.affectedCases.requestRecordal.rejectTitle';
                        }
                        request = this.translate.instant(request);
                        const message = this.translate.instant('caseview.affectedCases.requestRecordal.success', { request });
                        this.notificationService.success(message);
                    }
                }
                this._resultsGrid.clearSelection();
                this._resultsGrid.search();
                this.cdRef.detectChanges();
            }
        });
    };

    clearAffectedCaseAgent = (resultGrid: IpxKendoGridComponent) => {
        this.performBulkOperation(resultGrid, BulkOperationType.ClearAffectedCaseAgent);
    };

    deleteAffectedCases = (resultGrid: IpxKendoGridComponent) => {
        this.performBulkOperation(resultGrid, BulkOperationType.DeleteAffectedCases);
    };

    performBulkOperation = (resultGrid: IpxKendoGridComponent, operationType: BulkOperationType) => {
        this.isLoading = true;
        const notificationRef = operationType === BulkOperationType.DeleteAffectedCases ?
            this.ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message', null)
            : this.ipxNotificationService.openConfirmationModal('caseview.affectedCases.clearAgentTitle', 'caseview.affectedCases.confirmClearAgent', 'caseview.affectedCases.proceed', 'caseview.affectedCases.cancel', null, null, false, true, 'caseview.affectedCases.clearAgentCheckBoxLabel', true);
        notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
            .subscribe(() => {
                const selctedRowKeys = _.map(resultGrid.getRowSelectionParams().allSelectedItems, 'rowKey');
                const deselectedRowKeys = _.pluck(resultGrid.getRowSelectionParams().allDeSelectedItems, 'rowKey');
                this.service.performBulkOperation(this.caseKey, selctedRowKeys, deselectedRowKeys, resultGrid.getRowSelectionParams().isAllPageSelect, this.filterParams, operationType, notificationRef.content.isChecked).subscribe((response: { result?: string, errors?: Array<any>, cannotDeleteCaselistIds?: Array<string> }) => {
                    this.isLoading = false;
                    if (response) {
                        this.afterResponse(response);
                    }
                });
            });
        notificationRef.content.cancelled$.pipe(takeWhile(() => !!notificationRef))
            .subscribe(() => { this.isLoading = false; });
    };

    private afterResponse(response: any): void {
        if (response.result === 'success') {
            this.notificationService.success();
            this._resultsGrid.clearSelection();
            this.cannotDeleteAffectedCaseKeys = null;
        } else if (response.result === 'partialComplete') {
            this.cannotDeleteAffectedCaseKeys = response.cannotDeleteCaselistIds;
            this.ipxNotificationService.openAlertModal('modal.partialComplete', ' ', [this.translate.instant('modal.alert.partialComplete'), this.translate.instant('modal.alert.alreadyInUse')]);
            this._resultsGrid.clearSelection();
        } else if (response.result === 'error') {
            this.cannotDeleteAffectedCaseKeys = response.cannotDeleteCaselistIds;
            this.ipxNotificationService.openAlertModal('modal.unableToComplete', this.translate.instant('modal.alert.alreadyInUse'));
        }
        this._resultsGrid.search();
    }

    private resetForms(): void {
        this.service.updatedAffectedCases = null;
        const editedRows = this._resultsGrid.wrapper.wrapper.nativeElement.querySelectorAll('div.input-wrap.edited');
        if (editedRows && editedRows.length > 0) {
            editedRows.forEach(row => {
                this.renderer.removeClass(row, 'edited');
            });
        }
        this.editedRows = [];
        this.cannotDeleteAffectedCaseKeys = null;
        this._resultsGrid.refresh();
        this.cdRef.detectChanges();
    }

    setStatusColumn = () => {
        this.setStepStatus = this.localSettings.keys.caseView.affectedCases.setStepStatus.getLocal;
        this.toggleRecordalStepStatusColumn(this.setStepStatus);
        const hasSteps = this.gridOptions.columns.filter(col => {

            return col.field.startsWith('status');
        }).length > 0;
        this.recordalStepsTooltip = !hasSteps && this.isHosted ? 'caseview.affectedCases.recordalStepsTooltip' : '';
    };

    getFilterData = (obj: any): void => {
        this.filterParams = obj.filter;
        this.formGroup = obj.form;
        this.gridOptions._search();
        this._resultsGrid.clearSelection();
        this.showFilter = false;
    };

    encodeLinkData = (data: any) =>
        'api/search/redirect?linkData=' +
        encodeURIComponent(JSON.stringify(data));

    buildGridOptions(columnsData: Array<SearchResultColumn>): IpxGridOptions {
        const columns = this.buildColumns(columnsData);
        const pageSizeSetting = this.localSettings.keys.caseView.affectedCases.pageSize;

        return {
            autobind: true,
            pageable: { pageSizeSetting, pageSizes: [5, 10, 20, 50] },
            navigable: true,
            sortable: true,
            reorderable: false,
            scrollableOptions: this.anyColumnLocked ? { mode: scrollableMode.scrollable } : { mode: scrollableMode.none },
            customRowClass: (context) => {
                let returnValue = '';
                if (context.dataItem && this.cannotDeleteAffectedCaseKeys && this.cannotDeleteAffectedCaseKeys.length > 0 && this.cannotDeleteAffectedCaseKeys.indexOf(context.dataItem.rowKey) !== -1) {
                    returnValue += ' error';
                }

                return returnValue;
            },
            read$: (queryParams) => {
                if (this.filterParams) {
                    Object.assign(queryParams.filters, this.filterParams.filters);
                }
                const data = this.service.getAffectedCases(this.caseKey, queryParams, this.filterParams);

                return this.convertToGridData(data);
            },
            onDataBound: (data: any) => {
                if (data && data.total && this.topic.setCount) {
                    this.topic.setCount.emit(data.total);
                } else if (this.topic.setCount) {
                    this.topic.setCount.emit(0);
                }
                if (data) {
                    const newData = JSON.parse(JSON.stringify(data.data));
                    // const newData = __.cloneDeep(data.data);
                    this.service.setOriginalAffectedCases(newData);
                    if (this.service.updatedAffectedCases && this.service.updatedAffectedCases.length > 0) {
                        this.setPersistedSteps();
                    }
                }
            },
            columns,
            canAdd: false,
            selectable: this.canMaintainCase ? {
                mode: 'multiple'
            } : false,
            rowMaintenance: {
                rowEditKeyField: 'rowKey'
            },
            bulkActions: this.canMaintainCase ? this.actions : null,
            selectedRecords: {
                rows: {
                    rowKeyField: 'rowKey',
                    selectedKeys: []
                }
            }
        };
    }

    private readonly setPersistedSteps = () => {
        setTimeout(() => {
            this.resetCheckedColumns();
        }, 100);
        this.service.updatedAffectedCases.forEach(col => {
            this.stepColumns.forEach(val => {
                const dataRow = this.getDataRow(col.rowKey);
                const rowId = col.rowKey + '^' + val.field;
                if (dataRow) {
                    dataRow[val.field] = col[val.field];
                }
                setTimeout(() => {
                    const editedRow = this.elementRef.nativeElement.querySelector('ipx-checkbox[id="' + rowId + '"]');
                    if (dataRow) {
                        if (editedRow) {
                            this.editedRows.forEach(element => {
                                if (element === editedRow.id) {
                                    this.renderer.addClass(editedRow.firstElementChild, 'edited');
                                }
                            });
                        }
                    }
                }, 100);
            });
        });
    };

    private readonly resetCheckedColumns = (): void => {
        const editedRows = this._resultsGrid.wrapper.wrapper.nativeElement.querySelectorAll('div.input-wrap.edited');
        if (editedRows && editedRows.length > 0) {
            editedRows.forEach(row => {
                this.renderer.removeClass(row, 'edited');
            });
        }
    };

    getDataRow = (rowKey): any => {
        const dataRows = Array.isArray(this._resultsGrid.wrapper.data)
            ? this._resultsGrid.wrapper.data
            : (this._resultsGrid.wrapper.data).data;

        return dataRows.find(x => { return x.rowKey === rowKey; });
    };

    // tslint:disable-next-line: cyclomatic-complexity
    onChange = (rowdata: any, rowIndex: number, dataItem: any, context: any) => {
        this.service.setAffectedcases(dataItem);
        this.checkValidationAndEnableSave();
        const rowId = dataItem.rowKey + '^' + context.id;
        const editedRow = this.elementRef.nativeElement.querySelector('ipx-checkbox[id="' + rowId + '"]');
        if (editedRow) {
            this.renderer.addClass(editedRow.firstElementChild, 'edited');
            const checkedRowStep = JSON.parse(JSON.stringify(editedRow.id));
            this.editedRows.push(checkedRowStep);
        }
    };

    getChanges = (): { [key: string]: any; } => {
        const data = { affectedCases: { rows: [] } };
        this.stepColumns.forEach(col => {
            this.service.updatedAffectedCases.forEach(val => {
                if (val[col.field]) {
                    data.affectedCases.rows.push({ rowKey: val.rowKey, [col.field]: val[col.field] });
                } else {
                    data.affectedCases.rows.push({ rowKey: val.rowKey, [col.field]: false });
                }
            });
        });
        this.isLoading = true;
        this.cannotDeleteAffectedCaseKeys = null;

        return data;
    };

    onError = (): void => {
        if (this.topic.setErrors) {
            this.topic.setErrors(true);
        }
    };

    checkValidationAndEnableSave = (): void => {
        this.caseDetailService.hasPendingChanges$.next(true);
        if (this.service.updatedAffectedCases && this.service.updatedAffectedCases.length > 0) {
            this.caseDetailService.hasPendingChanges$.next(true);
        } else {
            this.caseDetailService.hasPendingChanges$.next(false);
        }
    };

    toggleRecordalStepStatusColumn(event: any): void {
        this.localSettings.keys.caseView.affectedCases.setStepStatus.setLocal(event);
        this.gridOptions.columns.forEach(col => {
            if (col.field.startsWith('status')) {
                col.hidden = !event;
            }
        });
        // tslint:disable-next-line: no-unbound-method
        if (angular.isDefined(this.gridOptions._search)) {
            this.gridOptions._search();
        }
    }

    disableStatus = (dataItem: any, id: string) => {
        const statusId = 'status' + id.substring(4);

        return dataItem[statusId] === AffectedCaseStatusEnum.Filed || dataItem[statusId] === AffectedCaseStatusEnum.Recorded || dataItem[statusId] === AffectedCaseStatusEnum.Rejected;
    };

    private readonly convertToGridData = (results: Observable<any>): Observable<any> => {

        return results.pipe(map(data => {
            this.totalRecords = data.totalRows;
            this.isLoading = false;

            return {
                data: data.rows,
                pagination: { total: data.totalRows }
            };
        }
        ));
    };

    buildColumns(selectedColumns: Array<SearchResultColumn>): any {
        if (selectedColumns && selectedColumns.length > 0) {
            const columns = [];
            this.anyColumnLocked = _.any(selectedColumns, (c) => c.isColumnFreezed) &&
                _.any(selectedColumns, (c) => !c.isColumnFreezed);
            if (this.anyColumnLocked) {
                const stickyHeader = document.querySelector('ipx-sticky-header');
                const gridEle = document.documentElement.clientWidth;
                const gridElementWidth = stickyHeader ? document.querySelector('ipx-sticky-header').parentElement.clientWidth - 35 : gridEle;
                this.casehelper.computeColumnsWidth(selectedColumns, gridElementWidth, false);
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
                    sortable: c.id === 'caseReference' ? true : false,
                    field: c.isHyperlink ? c.id + '.value' : c.id,
                    filter: false,
                    locked: c.isColumnFreezed,
                    width: this.anyColumnLocked ? c.width : 'auto',
                    headerClass: c.id.startsWith('step') ? 'k-header-center-aligned topic-section-text-wrap' : ''
                });
            });

            return columns;
        }

        return [];
    }

    byItem = (index: number, item: any): string => item;

    openRecordalSteps(): void {
        const modal = this.modalService.openModal(RecordalStepsComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                isHosted: this.isHosted,
                canMaintain: this.canMaintainCase,
                caseKey: this.caseKey
            }
        });
        modal.content.onClose$.subscribe(
            (event: boolean) => {
                if (event) {
                    this.service.getColumns$(this.caseKey).subscribe(data => {
                        const columns = this.buildColumns(data);
                        this._resultsGrid.resetColumns(columns);
                        this._resultsGrid.search();
                        this.setStatusColumn();
                        this.stepColumns = _.filter(this.gridOptions.columns, (col) => {
                            return col.field.startsWith('step');
                        });
                    });
                }
            }
        );
    }

    openAddAffectedCases(): void {
        const modal = this.modalService.openModal(AddAffectedCaseComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                caseKey: this.caseKey
            }
        });
        modal.content.onClose$.subscribe(
            (event: boolean) => {
                this._resultsGrid.search();
            }
        );
    }

    toggleFilter = (): void => {
        this.showFilter = !this.showFilter;
    };

    setAffectedCaseAgent = (resultGrid: IpxKendoGridComponent) => {
        if (resultGrid.getRowSelectionParams().isAllPageSelect) {
            this.openSetAgent(null, true, resultGrid.getRowSelectionParams().allDeSelectedItems);
        } else if (_.any(resultGrid.getRowSelectionParams().allSelectedItems)) {
            this.openSetAgent(resultGrid.getRowSelectionParams().allSelectedItems);
        }
    };

    openSetAgent = (selectedCases: any, isAllPageSelect = false, deselectedRows: any = null) => {
        this.modalRef = this.modalService.openModal(AffectedCasesSetAgentComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                affectedCases: selectedCases,
                mainCaseId: this.caseKey,
                showWebLink: this.showWebLink,
                isAllPageSelect,
                filterParams: this.filterParams,
                deselectedRows
            }
        });

        this.modalRef.content.onClose$.subscribe(value => {
            if (value) {
                if (value === 'success') {
                    this.notificationService.success('caseview.affectedCases.setAgent.saved');
                } else {
                    this.notificationService.info({
                        title: 'caseview.affectedCases.setAgent.title',
                        message: 'caseview.affectedCases.setAgent.backgroundInfo'
                    });
                }
                this._resultsGrid.clearSelection();
                this._resultsGrid.search();
                this.cdRef.detectChanges();
            }
        });
    };
}

export class AffectedCasesTopicParams extends TopicParam {
    showWebLink: boolean;
}

export class CaseAffectedCasesTopic extends Topic {
    readonly key = 'affectedCases';
    readonly title = caseViewTopicTitles.affectedCases;
    readonly component = AffectedCasesComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: AffectedCasesTopicParams) {
        super();
    }
}