import { AfterContentInit, AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ContentChild, ContentChildren, EventEmitter, HostListener, Input, NgZone, OnDestroy, OnInit, Output, QueryList, Renderer2, TemplateRef, ViewChild } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { ColumnComponent, ColumnReorderEvent, GridComponent, GridDataResult, PageChangeEvent, PagerSettings, RowClassArgs, SelectableSettings } from '@progress/kendo-angular-grid';
import { ContextMenuComponent, MenuEvent } from '@progress/kendo-angular-menu';
import { GroupDescriptor, orderBy, process, SortDescriptor, State } from '@progress/kendo-data-query';
import * as angular from 'angular';
import { LocalSetting } from 'core/local-settings';
import { BehaviorSubject, fromEvent } from 'rxjs';
import { map } from 'rxjs/internal/operators/map';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { IpxGridDataBindingDirective } from './ipx-grid-data-binding.directive';
import { GridHelper } from './ipx-grid-helper';
import { IpxGridOptions } from './ipx-grid-options';
import { GridSelectionHelper } from './ipx-grid-selection-helper';
import { GridColumnDefinition, MenuDataItemEventData, NavigationActions, PageSettings, TaskMenuItem } from './ipx-grid.models';
import { IPXKendoGridSelectAllService } from './ipx-kendo-grid-selectall.service';
import { IpxGroupingService } from './ipx-kendo-grouping.service';
import { EditTemplateColumnFieldDirective, TemplateColumnFieldDirective } from './ipx-template-column-field.directive';
import { GridToolbarComponent } from './toolbar/grid-toolbar.component';

@Component({
    selector: 'ipx-kendo-grid',
    templateUrl: './ipx-kendo-grid.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class IpxKendoGridComponent implements OnInit, AfterViewInit, OnDestroy, AfterContentInit {
    @Input() set dataOptions(options: IpxGridOptions) {
        if (options) {
            this._dataOptions = options;
            this.setUpDataOptions();
            this.cdRef.detectChanges();
        }
    }
    get dataOptions(): IpxGridOptions {
        return this._dataOptions;
    }
    @Input() editor: any;
    @Input() noResultsHint: string;
    @Input() showPreview = false;
    @Output() readonly rowSelectionChanged = new EventEmitter<any>();
    @Output() readonly rowOnMaintnance = new EventEmitter<any>();
    @Output() readonly dataItemClicked = new EventEmitter<any>();
    @Output() readonly pageChanged = new EventEmitter();
    @Output() readonly rowAdded = new EventEmitter();
    @Output() readonly dataBound = new EventEmitter<any>();
    @Output() readonly menuItemSelected = new EventEmitter<MenuDataItemEventData>();
    @Output() readonly popupOpen = new EventEmitter();
    @Output() readonly totalRecord = new EventEmitter();
    @Output() readonly editRowEvent = new EventEmitter<any>();
    @Output() readonly addRowEvent = new EventEmitter<any>();
    @Output() readonly cancelRowEditEvent = new EventEmitter<any>();
    @Output() readonly deleteRowEvent = new EventEmitter<any>();
    @Output() readonly onDetailExpand = new EventEmitter<any>();
    @Output() readonly onDetailCollapse = new EventEmitter<any>();
    @Output() readonly duplicateRowEvent = new EventEmitter<any>();
    @Output() readonly onFilterChanged = new EventEmitter<any>();
    @Output() readonly onCellDbClick = new EventEmitter<any>();

    @ContentChildren(TemplateColumnFieldDirective) templates: QueryList<TemplateColumnFieldDirective>;
    @ContentChildren(EditTemplateColumnFieldDirective) editTemplates: QueryList<EditTemplateColumnFieldDirective>;
    @ContentChildren(TemplateRef) defaultTemplates: QueryList<TemplateRef<any>>;
    @ContentChild(GridToolbarComponent) gridToolbarRef: GridToolbarComponent;
    @ViewChild(IpxGridDataBindingDirective, { static: true }) data: IpxGridDataBindingDirective;
    @ViewChild(GridComponent, { static: true }) wrapper: GridComponent;
    gridmenu: any;
    @ViewChild('gridmenu', { static: true }) gridContextMenu: ContextMenuComponent;
    @Input() autoApplySelection = true;
    @Input() items = Array<TaskMenuItem>();
    gridHelper = new GridHelper();

    itemName: any;
    anyColumnLocked: boolean;
    performActionsAfterViewInit: Array<() => void> = [];
    rowEditFormGroups: { [rowKey: string]: FormGroup };
    maintainance: any;
    rowMaintenance: any;
    gridMessage = '';
    currentEditRowIdx: number;
    minReorderIndex?: number;
    showToolBar = false;
    private _dataOptions: IpxGridOptions;
    private domHeaderSubscriptions: any;
    private initialDataLoded = false;
    private focusRowIndexValue?: number;
    showContextMenu: boolean;
    taskMenuDataItem: any;
    activeTaskMenuItems: Array<string> = [];
    storeGroupsForRefresh: Array<GroupDescriptor>;
    isShowTemplateForGroup = false;
    private readonly defaultPageableSettings: PagerSettings = {
        type: 'numeric',
        pageSizes: [10, 20, 50, 100],
        previousNext: true,
        buttonCount: 5
    };
    pageable: PagerSettings | boolean = false;
    pageSize = 10;
    gridSelectionHelper: GridSelectionHelper;
    isRowEditedState: boolean;
    private _gridTotal: number;
    allItems: Array<any>;
    allSelectedItem: Array<any> = [];
    clickedCellDetail: any;
    constructor(
        private readonly ngZone: NgZone,
        private readonly renderer: Renderer2,
        private readonly cdRef: ChangeDetectorRef,
        private readonly translate: TranslateService,
        readonly selectAllService: IPXKendoGridSelectAllService,
        private readonly ipxGroupingService: IpxGroupingService
    ) {

        this.gridSelectionHelper = new GridSelectionHelper(selectAllService);
        this.maintainance = {
            picklistCanMaintain: false,
            showView: false,
            showEdit: false,
            showDuplicate: false,
            showDelete: false
        };
    }

    ngOnInit(): void {
        this.ipxGroupingService.isProcessCompleted$.subscribe(result => {
            this.isShowTemplateForGroup = result;
        });
        this.isShowTemplateForGroup = false;
        const errorMsg = this.unSupported();
        if (errorMsg) {
            throw new TypeError(errorMsg);
        }
        this.gridSelectionHelper.rowSelectionChanged.subscribe((data: any) => {
            this.rowSelectionChanged.emit(data);
        });
        this.manageMaintainFormGroup();
    }

    private readonly setUpDataOptions = () => {
        this.restoreSavedGroupOnRefresh();
        this.showToolBar = this._dataOptions.columnPicker || this._dataOptions.canAdd || this.gridToolbarRef !== null;
        this.minReorderIndex = _.findLastIndex(this._dataOptions.columns, { fixed: true }) + ((this._dataOptions.selectable && (this._dataOptions.selectable as SelectableSettings).mode === 'multiple') ? 1 : 0);
        this._dataOptions._search = this.search;
        this._dataOptions._refresh = this.refresh;
        this._dataOptions._selectPage = this.selectPage;
        this._dataOptions._selectRows = this.selectRows;
        this._dataOptions.navigateByIndex = this.navigateByIndex;
        this._dataOptions.editRow = this.editRowAndDetails;
        this._dataOptions.removeRow = this.removeRow;
        this._dataOptions.addOnSave = this.addOnSave;
        const colPreference = this.gridHelper.setColumnsPreference(this._dataOptions);
        if (colPreference) {
            this._dataOptions.columns = colPreference.dataOptions.columns;
        }

        this._dataOptions._closeEditMode = (): void => {
            this.closeRow();
        };
        if (this._dataOptions.picklistCanMaintain && this._dataOptions.maintainanceMetaData$) {
            this._dataOptions.maintainanceMetaData$.subscribe((value) => {
                this.maintainance.picklistCanMaintain = value && value.maintainabilityActions && value.maintainabilityActions.allowView ||
                    value.maintainability.canAdd || value.maintainability.canEdit || value.maintainability.canDelete;
                this.maintainance.showView = value.maintainabilityActions.allowView && !value.maintainability.canEdit;
                this.maintainance.showEdit = value.maintainabilityActions.allowEdit && value.maintainability.canEdit;
                this.maintainance.showDuplicate = value.maintainabilityActions.allowDuplicate && value.maintainability.canAdd;
                this.maintainance.showDelete = value.maintainabilityActions.allowDelete && value.maintainability.canDelete;
            });
        }

        if (this._dataOptions.rowMaintenance && (Object.keys(this._dataOptions.rowMaintenance).length > 0)) {
            this.rowMaintenance = this._dataOptions.rowMaintenance;
        }

        if (this._dataOptions.enableTaskMenu === undefined) {
            this._dataOptions.enableTaskMenu = true;
        }

        if (!this.dataOptions.detailTemplate) {
            this.dataOptions.showExpandCollapse = false;
        }
        this.setOptions();
        this.cdRef.detectChanges();
    };

    groupChange(groups: Array<GroupDescriptor>): void {
        this.showContextMenu = groups.length > 0 ? false : this.dataOptions.showContextMenu;
        this.isShowTemplateForGroup = _.any(groups);
    }

    refresh = (): void => {
        this.dataOptions.groups = this.storeGroupsForRefresh.length ? this.storeGroupsForRefresh : [];
        this.data.refreshGrid();
        this.gridSelectionHelper.ClearSelection();
    };

    ngAfterContentInit(): void {
        this.anyColumnLocked = this.gridHelper.isAnyColumnLokced(this._dataOptions);
    }

    ngAfterViewInit(): void {
        const content = document.querySelector('.main-content-scrollable');
        if (!!content) {
            const scroll$ = fromEvent(content, 'scroll').pipe(map(() => content));
            if (!!scroll$) {
                scroll$.subscribe(() => {
                    const popups = document.querySelectorAll('.k-animation-container [data-role="popup"]');
                    Array.from(popups).forEach(item => {
                        item.setAttribute('style', 'display:none;');
                    });
                });
            }
        }

        const columnTemplate = this.gridHelper.rebuildColumnTemplates(this._dataOptions, this.templates, this.editTemplates);
        if (columnTemplate) {
            this._dataOptions.columns = columnTemplate.dataOptions.columns;
        }
        this.cdRef.markForCheck();
        const selectedItems = this._dataOptions && this._dataOptions.selectedRecords && this._dataOptions.selectedRecords.rows && this._dataOptions.selectedRecords.rows.selectedRecords || [];
        this.gridSelectionHelper.allSelectedItems = this.gridSelectionHelper.allSelectedItems || selectedItems;

        if (this.dataOptions.showExpandCollapse) {
            const element = angular.element(
                '<a tabindex="-1" class="k-icon k-i-expand no-underline" id ="expandCollapseAll"></a>'
            );
            const expanderEl = this.wrapper.wrapper.nativeElement.querySelector('thead.k-grid-header tr th.k-hierarchy-cell.k-header');
            if (expanderEl) {
                this.renderer.appendChild(expanderEl, element[0]);
                this.renderer.listen(element[0], 'click', (e) => {
                    this.expandCollapseAll(false);
                });
            }
        }

        if (this.dataOptions.scrollableOptions && this.dataOptions.scrollableOptions.mode === scrollableMode.virtual) {
            this.wrapper.rowHeight = this._dataOptions.scrollableOptions.rowHeight;
        }

        if (this._dataOptions.filterable) {
            const header = this.wrapper.wrapper.nativeElement.getElementsByClassName('k-grid-header')[0];
            this.ngZone.runOutsideAngular(() => {
                this.domHeaderSubscriptions = this.renderer.listen(header, 'click', (e) => {
                    if (this.gridHelper.hasClasses(e.target, 'k-grid-filter k-i-filter')) {
                        const classTarget = e.target.tagName === 'A' ? e.target : e.target.parentNode;
                        classTarget.classList.add('k-state-border-down');
                        const kendoPopups = document.getElementsByTagName('kendo-popup');
                        if (kendoPopups.length > 0) {
                            const filterMenuList = kendoPopups[0].getElementsByClassName('k-filter-menu-container');
                            const filterMenu = filterMenuList[0];
                            if (filterMenu) {
                                const buttonsDiv = filterMenu.getElementsByClassName('k-action-buttons');
                                if (buttonsDiv.length > 0) {
                                    this.renderer.listen(buttonsDiv[0].firstChild, 'click', (e1) => {
                                        this.onFilterChanged.emit();
                                    });
                                    this.renderer.listen(buttonsDiv[0].lastChild, 'click', (e2) => {
                                        this.onFilterChanged.emit();
                                    });
                                    buttonsDiv[0].classList.remove('k-button-group');
                                    buttonsDiv[0].classList.remove('k-action-buttons');
                                }
                                let aDomFilterSubscription = this.renderer.listen('document', 'click', ({ target }) => {
                                    const isWithinFilter = this.gridHelper.closest(target, node => this.gridHelper.hasClasses(node, 'k-filter-menu-container') || (node === e.target && kendoPopups.length > 0));
                                    if (!(isWithinFilter && target.tagName !== 'BUTTON')) {
                                        classTarget.classList.remove('k-state-border-down');
                                        if (aDomFilterSubscription) {
                                            aDomFilterSubscription();
                                            aDomFilterSubscription = undefined;
                                        }
                                    }
                                });
                            }
                        } else {
                            classTarget.classList.remove('k-state-border-down');
                        }
                    }
                });
            });
        }
        this.performActionsAfterViewInit.forEach(callback => callback());
        if (this.dataOptions.scrollableOptions && this.dataOptions.scrollableOptions.height && (this.dataOptions.scrollableOptions.mode === scrollableMode.virtual || this.dataOptions.scrollableOptions.mode === scrollableMode.scrollable)) {
            setTimeout(() => {
                this.applyScrollableHeight();
            }, 200);
        }
        this.cdRef.markForCheck();
    }

    applyScrollableHeight = (): void => {
        const element = this.wrapper.wrapper.nativeElement;

        const scrollableElement = element.getElementsByClassName(
            'k-grid-content k-virtual-content'
        )[0];

        this.renderer.setStyle(scrollableElement, 'height', this.dataOptions.scrollableOptions.height + 'px');
    };

    resetColumns = (columns: Array<GridColumnDefinition>) => {
        this.dataOptions.columns = columns;
        const columnTemplate = this.gridHelper.rebuildColumnTemplates(this._dataOptions, this.templates, this.editTemplates);
        if (columnTemplate) {
            this._dataOptions.columns = columnTemplate.dataOptions.columns;
        }
        this.persistEditingStates();
        this.cdRef.markForCheck();
    };

    ngOnDestroy(): void {
        if (this.domHeaderSubscriptions) {
            this.domHeaderSubscriptions();
            this.domHeaderSubscriptions = undefined;
        }
    }
    // tslint:disable-next-line: prefer-inline-decorator
    @HostListener('keydown', ['$event'])
    onkeypress = (event: KeyboardEvent): void => {
        const target = event.target as HTMLElement;
        switch (event.key) {
            case 'ArrowUp':
            case 'Up':
                if (!!target && !target.closest('textarea')) {
                    this.preventDefault(event);
                    this.navigate(NavigationActions.PrevRow);
                }
                break;
            case 'ArrowDown':
            case 'Down':
                if (!!target && !target.closest('textarea')) {
                    this.preventDefault(event);
                    this.navigate(NavigationActions.NextRow);
                }
                break;
            case 'Home':
                if (!!target && !target.closest('textarea, input[type="text"]')) {
                    this.preventDefault(event);
                    this.navigate(NavigationActions.FirstPage);
                }
                break;
            case 'End':
                if (!!target && !target.closest('textarea, input[type="text"]')) {
                    this.preventDefault(event);
                    this.navigate(NavigationActions.LastPage);
                }
                break;
            case 'PageUp':
                this.preventDefault(event);
                this.navigate(NavigationActions.PrevPage);
                break;
            case 'PageDown':
                this.preventDefault(event);
                this.navigate(NavigationActions.NextPage);
                break;
            default:
                break;
        }
    };

    navigateByIndex = (index: number): void => {
        const selection = (this.wrapper.data instanceof Array) ? this.wrapper.data[index] : this.wrapper.data.data[index];
        this.wrapper.selectionChange.emit({ selectedRows: [{ dataItem: selection, index }], deselectedRows: [], ctrlKey: null });
        this.focusRowIndexValue = index;
        this.gridSelectionHelper.rowSelection = [index];
        this.emitDataItemByFocusIndex();
    };

    readonly navigate = (action: NavigationActions): void => {
        this.changeFocus(action);
    };

    private readonly changeFocus = (action: NavigationActions): void => {
        const totalCount = (this.wrapper.data instanceof Array) ? this.wrapper.data.length : this.wrapper.data.total;
        const hasPaging = !!this.pageable && this.wrapper.pageSize !== 0;
        switch (action) {
            case NavigationActions.PrevRow:
                if (this.focusRowIndexValue > Math.max(this.wrapper.skip, 0)) {
                    this.caliberateIndex(this.focusRowIndexValue - 1);
                }

                break;
            case NavigationActions.NextRow:
                if (this.focusRowIndexValue < Math.min((this.wrapper.skip + this.wrapper.pageSize), totalCount) - 1) {
                    this.caliberateIndex(this.focusRowIndexValue + 1);
                }
                break;
            case NavigationActions.FirstPage:
                if (hasPaging && this.focusRowIndexValue > this.wrapper.pageSize) {
                    this.wrapper.skip = 0;
                    this.data.selectPage(this.wrapper.skip);
                    this.focusRow(this.wrapper.skip);
                }
                break;
            case NavigationActions.LastPage:
                if (hasPaging && this.focusRowIndexValue < (totalCount - this.wrapper.pageSize)) {
                    this.wrapper.skip = Math.floor(totalCount / this.wrapper.pageSize) * this.wrapper.pageSize;
                    this.data.selectPage(this.wrapper.skip);
                    this.focusRow(this.wrapper.skip);
                }
                break;
            case NavigationActions.PrevPage:
                if (hasPaging && this.focusRowIndexValue >= this.wrapper.pageSize) {
                    this.wrapper.skip = (Math.floor(this.focusRowIndexValue / this.wrapper.pageSize) - 1) * this.wrapper.pageSize;
                    this.data.selectPage(this.wrapper.skip);
                    this.focusRow(this.wrapper.skip);
                }
                break;
            case NavigationActions.NextPage:
                if (hasPaging && this.focusRowIndexValue < Math.floor(totalCount / this.wrapper.pageSize) * this.wrapper.pageSize) {
                    this.wrapper.skip = (Math.floor(this.focusRowIndexValue / this.wrapper.pageSize) + 1) * this.wrapper.pageSize;
                    this.data.selectPage(this.wrapper.skip);
                    this.focusRow(this.wrapper.skip);
                }
                break;
            default:
                break;
        }
        this.emitDataItemByFocusIndex();
    };
    focusRow = (index: number, pageIndex?: boolean): void => {
        let usedIndex = index;
        if (pageIndex) {
            usedIndex += this.wrapper.pageable ? (this.wrapper.skip) : 0;
        }
        this.focusRowIndexValue = usedIndex;
        this.wrapper.focusCell(this.focusRowIndexValue + 1, 0);
    };
    private readonly emitDataItemByFocusIndex = (): void => {
        const onPageIndex = this.focusRowIndexValue % this.wrapper.pageSize;
        this.dataItemClicked.emit((this.wrapper.data instanceof Array) ? this.wrapper.data[onPageIndex] : this.wrapper.data.data[onPageIndex]);
    };

    rowCallBack = (context: RowClassArgs): any => {
        let returnValue = '';
        if (this._dataOptions) {
            if (this._dataOptions.customRowClass) {
                returnValue = this._dataOptions.customRowClass(context) as string;
            }
            if (!this._dataOptions.draggable && context.index === this.focusRowIndexValue && returnValue.indexOf('k-state-selected selected') === -1) {
                returnValue += ' k-state-selected selected';
            }
            if (this._dataOptions.dimRowsColumnName && context.dataItem[this._dataOptions.dimRowsColumnName]) {
                returnValue += ' dim ';
            }
            if (this.rowMaintenance && context.dataItem) {
                returnValue += context.dataItem.status === rowStatus.deleting ? ' deleted' : '';
            }
            if (this._dataOptions.groups && this._dataOptions.groups.length > 0 && !this.anyColumnLocked) {
                returnValue += ' k-grouping-row';
            }
        }

        return returnValue;
    };

    addOnSave = (): void => {
        this.onAdd();
    };

    onAdd(): void {
        if (this._dataOptions.enableGridAdd) {
            if (this._dataOptions.gridAddDelegate) {
                this._dataOptions.gridAddDelegate();
            } else {
                this.addRow();
            }
        }
    }

    addRow(): void {
        const rowIndex = this.data.addRow(this._dataOptions.itemTemplate);
        this.gridMessage = '';
        if (this._dataOptions.disableMultiRowEditing) {
            this.isRowEditedState = true;
        }
        this.rowAdded.emit(rowIndex);
        if (this.rowMaintenance) {
            this.rowAddHandler(rowIndex);

            return;
        }
        this.currentEditRowIdx = rowIndex;
        this.wrapper.editRow(rowIndex, this._dataOptions.createFormGroup());
        this._dataOptions.enableGridAdd = false;
    }

    closeRow(collapseRow = true, detectChanges = false): void {
        if (this._dataOptions.disableMultiRowEditing) {
            this.isRowEditedState = false;
        }
        this.data.closeRow(this.currentEditRowIdx, collapseRow);
        if (detectChanges) {
            this.cdRef.detectChanges();
        }
    }

    editRowAndDetails = (rowIdx = 0, dataItem: any, editDetail?: boolean): void => {
        this.currentEditRowIdx = rowIdx;
        this.wrapper.editRow(rowIdx, this._dataOptions.createFormGroup(dataItem));
        this.wrapper.expandRow(rowIdx);
        this.cdRef.markForCheck();
    };

    removeRow = (rowIdx?: number): void => {
        this.data.removeRow(rowIdx ? rowIdx : this.currentEditRowIdx);
        this.cdRef.markForCheck();
    };

    rowAddHandler = (rowIndex): void => {
        if (this.dataOptions.rowMaintenance && this.dataOptions.rowMaintenance.rowEditKeyField) {
            const dataItem = { status: rowStatus.Adding };
            if (this.dataOptions.pageable) {
                let newKey;
                if (this.rowEditFormGroups) {
                    newKey = Object.keys(this.rowEditFormGroups).filter(k =>
                        this.rowEditFormGroups[k].value.status === rowStatus.Adding).length;
                }
                dataItem[this.dataOptions.rowMaintenance.rowEditKeyField] = newKey ? 'new_' + newKey : 'new_0';
            } else {
                const keys = Array.isArray(this.wrapper.data)
                    ? this.wrapper.data.map(d => d ? d[this.dataOptions.rowMaintenance.rowEditKeyField] + 1 : 0)
                    : (this.wrapper.data).data.map(d => d ? d[this.dataOptions.rowMaintenance.rowEditKeyField] + 1 : 0);

                dataItem[this.dataOptions.rowMaintenance.rowEditKeyField] = Math.max.apply(Math, keys);
            }
            if (!this._dataOptions.maintainFormGroup$) {
                const formGroup = this._dataOptions.createFormGroup(dataItem);
                this.setupDataItem(dataItem, formGroup, rowIndex);
            }

            this.addRowEvent.emit({ rowIndex, dataItem });
            if (this.dataOptions.showExpandCollapse && this.wrapper.skip === 0) {
                this.expandCollapseAll(true, rowIndex);
            }
        }
    };

    setupDataItem = (dataItem, formGroup, rowIndex): void => {
        if (formGroup) {
            let curRowIndex = rowIndex;
            this._dataOptions.formGroup = formGroup;
            Object.assign(dataItem, formGroup.value);
            if (Array.isArray(this.wrapper.data)) {
                this.wrapper.data[curRowIndex] = dataItem;
            } else {
                (this.wrapper.data).data[curRowIndex] = dataItem;
            }
            this.rowEditFormGroups = {
                ...(this.rowEditFormGroups || {}), ...{ [String(dataItem[this.dataOptions.rowMaintenance.rowEditKeyField])]: formGroup }
            };
            if (this.wrapper.skip > 0) {
                curRowIndex = this.wrapper.skip + curRowIndex;
            }

            this.wrapper.editRow(curRowIndex, formGroup);
            this.cdRef.detectChanges();
        }
    };

    manageMaintainFormGroup = (): void => {
        if (this._dataOptions.maintainFormGroup$) {
            this._dataOptions.maintainFormGroup$.subscribe((value: any) => {
                if (value) {
                    this.wrapper.closeRow(value.rowIndex);
                    this.setupDataItem(value.dataItem, value.formGroup, value.rowIndex);
                }
            });
        }
    };

    rowEditHandler = (sender, rowIndex, dataItem): void => {
        if (this._dataOptions.disableMultiRowEditing) {
            this.isRowEditedState = true;
        }
        let curRowIndex = rowIndex;
        if (this.wrapper.skip > 0 && this.wrapper.skip <= curRowIndex) {
            curRowIndex = curRowIndex - this.wrapper.skip;
        }
        if (this.dataOptions.rowMaintenance && this.dataOptions.rowMaintenance.rowEditKeyField) {
            const key = String(dataItem[this.dataOptions.rowMaintenance.rowEditKeyField]);
            let formGroup: any;
            if (dataItem.status === rowStatus.Adding) {
                formGroup = this.rowEditFormGroups[key];
            } else {
                dataItem.status = rowStatus.editing;
                if (!this._dataOptions.maintainFormGroup$) {
                    formGroup = this._dataOptions.createFormGroup(dataItem);
                    this.setupDataItem(dataItem, formGroup, curRowIndex);
                }
            }

        }
        this.editRowEvent.emit({ rowIndex: curRowIndex, dataItem });
    };

    rowDuplicateHandler = (rowIndex, dataItem): void => {
        this.duplicateRowEvent.emit({ rowIndex, dataItem });
    };

    checkChanges = () => {
        this.cdRef.markForCheck();
    };

    rowCancelHandler = (sender, rowIndex, dataItem): void => {
        let curRowIndex = rowIndex;
        if (this.wrapper.skip > 0 && curRowIndex > this.wrapper.skip) {
            curRowIndex = curRowIndex - this.wrapper.skip;
        }
        if (this.dataOptions.rowMaintenance && this.dataOptions.rowMaintenance.rowEditKeyField) {
            const key = String(dataItem[this.dataOptions.rowMaintenance.rowEditKeyField]);
            if (dataItem.status === rowStatus.Adding) {
                this.wrapper.closeRow(curRowIndex);
                if (Array.isArray(this.wrapper.data)) {
                    this.wrapper.data.splice(curRowIndex, 1);
                } else {
                    (this.wrapper.data).data.splice(curRowIndex, 1);
                }
                if (this.rowEditFormGroups) {
                    // tslint:disable-next-line:no-dynamic-delete
                    delete this.rowEditFormGroups[key];
                }
            } else {
                delete dataItem.status;
                if (dataItem.error) {
                    delete dataItem.error;
                }
                if (Array.isArray(this.wrapper.data)) {
                    this.wrapper.data[curRowIndex] = dataItem;
                } else {
                    (this.wrapper.data).data[curRowIndex] = dataItem;
                }
            }
            this.wrapper.closeRow(curRowIndex);
            if (this.rowEditFormGroups) {
                // tslint:disable-next-line:no-dynamic-delete
                delete this.rowEditFormGroups[key];
            }
            this._dataOptions.formGroup = undefined;
            this.cancelRowEditEvent.emit(key);
        }
    };

    rowDeleteHandler = (sender, rowIndex: number, dataItem): void => {
        if (this.dataOptions.rowMaintenance.rowEditKeyField) {
            const key = String(dataItem[this.dataOptions.rowMaintenance.rowEditKeyField]);
            if (dataItem.status === rowStatus.Adding) {

                let data = this.getCurrentData();
                let maxRowCount = data.length;
                for (let i = rowIndex; i < maxRowCount; i++) {
                    this.wrapper.closeRow(i);
                }

                this.data.removeRow(rowIndex);
                // tslint:disable-next-line:no-dynamic-delete
                delete this.rowEditFormGroups[key];

                data = this.getCurrentData();
                data = data.filter(x => x && x !== undefined);
                maxRowCount = data.length;
                for (let i = rowIndex; i < maxRowCount; i++) {
                    const d = data[i];
                    const fg = this.rowEditFormGroups[d[this.dataOptions.rowMaintenance.rowEditKeyField]];
                    this.wrapper.editRow(i, fg);
                }

            } else {
                dataItem.status = rowStatus.deleting;
                if (this.dataOptions.rowMaintenance) {
                    this.rowEditFormGroups = {
                        ...(this.rowEditFormGroups || {}), ...{
                            [String(dataItem[this.dataOptions.rowMaintenance.rowEditKeyField])]: new FormGroup({
                                rowKey: new FormControl(dataItem[this.dataOptions.rowMaintenance.rowEditKeyField]),
                                status: new FormControl(dataItem.status)
                            })
                        }
                    };

                    Object.assign(this.rowEditFormGroups[String(dataItem[this.dataOptions.rowMaintenance.rowEditKeyField])].value, dataItem);
                }
            }

            this.cdRef.markForCheck();
        }
        this.deleteRowEvent.emit(dataItem);
    };

    pageRowIndex = (rowIndex: number): number => {
        if (this.dataOptions.pageable && this.wrapper.pageSize > 0) {
            return rowIndex % this.wrapper.pageSize;
        }

        return rowIndex;
    };

    isValid = (): boolean => {
        let _isValid = true;
        if (this._dataOptions.rowMaintenance && this._dataOptions.rowMaintenance.rowEditKeyField && this.rowEditFormGroups) {
            Object.keys(this.rowEditFormGroups).map(k => {
                if (this.rowEditFormGroups[k].invalid) {
                    _isValid = false;

                    return;
                }
            });
        }

        return _isValid;
    };

    isDirty = (): boolean => {
        let _isDirty = false;
        if (this.dataOptions.rowMaintenance && this._dataOptions.rowMaintenance.rowEditKeyField && this.rowEditFormGroups) {
            Object.keys(this.rowEditFormGroups).map(k => {
                if (this.rowEditFormGroups[k].dirty) {
                    _isDirty = true;

                    return;
                }
            });
        }

        return _isDirty;
    };

    trackByColumnField = (index: number, col: GridColumnDefinition): string => {
        return col.field;
    };

    showDetailTemplate = (dataItem: any, index: number): boolean => {
        if (this._dataOptions.detailTemplateShowCondition !== undefined) {
            return this._dataOptions.detailTemplateShowCondition(dataItem, index);
        }

        return true;
    };

    showGroupDetailTemplate = (dataItem: any, index: number): boolean => {
        return dataItem.items && _.any(this._dataOptions.groups);
    };

    showRevertButton(dataItem: any, rowMaintenance: any): boolean {
        return dataItem && rowMaintenance.canEdit &&
            (dataItem.status === rowStatus.deleting || (!this._dataOptions.maintainFormGroup$ && dataItem.status === rowStatus.editing))
            && (!dataItem.showRevertAttributes || dataItem.showRevertAttributes.display);
    }

    showEditButton(dataItem: any, rowMaintenance: any): boolean {
        let result = true;
        if (this._dataOptions.disableMultiRowEditing && this.isRowEditedState) {
            result = false;
        } else {
            result = dataItem && rowMaintenance.canEdit &&
                !this.showRevertButton(dataItem, rowMaintenance) && (!dataItem.status || dataItem.status !== 'D') &&
                (!dataItem.showEditAttributes || dataItem.showEditAttributes.display);
        }

        return result;
    }

    showDeleteButton(dataItem: any, rowMaintenance: any): boolean {
        return dataItem && rowMaintenance.canDelete && dataItem.status !== 'D' && (!dataItem.showDeleteAttributes || dataItem.showDeleteAttributes.display);
    }

    expandCollapseAll(persistState: boolean, rowIndex?: number): void {
        const expanderEl = this.wrapper.wrapper.nativeElement.querySelector('thead.k-grid-header tr th.k-hierarchy-cell.k-header').firstElementChild;
        const isExpanded = this.gridHelper.hasClasses(expanderEl, 'k-i-expand');
        if (!persistState) {
            if (isExpanded) {
                this.renderer.removeClass(expanderEl, 'k-i-expand');
                this.renderer.addClass(expanderEl, 'k-i-collapse');
                this.expandAll();
            } else {
                this.renderer.removeClass(expanderEl, 'k-i-collapse');
                this.renderer.addClass(expanderEl, 'k-i-expand');
                this.collapseAll();
            }
        } else {
            isExpanded ? this.collapseAll(rowIndex) : this.expandAll(rowIndex);
        }
        this.cdRef.markForCheck();
    }

    expandAll(rowIndex?: number): void {
        if (rowIndex || rowIndex === 0) {
            this.wrapper.expandRow(rowIndex);

            return;
        }
        const data: Array<any> = this.getCurrentData();
        data.forEach((item, idx) => {
            this.wrapper.expandRow(this.wrapper.skip + idx);
        });
    }

    pageChange({ skip, take }: PageChangeEvent): void {
        const storagePageData = this.gridHelper.storePageSizeToLocalStorage(take, this.pageLocalSetting);
        if (storagePageData) {
            const oldPageSize = storagePageData.oldPagesize;
            this.pageChanged.emit({ skip, take, oldPageSize });
        }
        if (this.dataOptions.showExpandCollapse) {
            this.expandCollapseAll(true);
        }
    }

    manageBarWidth = (): void => {

        const element = document.querySelector<HTMLDivElement>('div.k-grid-aria-root > table');
        if (!element) {
            return;
        }

        const groupByElement = document.querySelector<HTMLDivElement>('.k-grouping-header');
        const pagerElement = document.querySelector<HTMLDivElement>('.k-pager-wrap');
        const alertElement = document.querySelector<HTMLDivElement>('#grid-alert .alert.alert-info');

        if (groupByElement) {
            groupByElement.style.width = element.scrollWidth + 'px';
        }
        if (pagerElement && this.dataOptions.pageable) {
            pagerElement.style.width = element.scrollWidth > 0 ? element.scrollWidth + 'px' : '100%';
        }
        if (alertElement) {
            alertElement.style.width = element.scrollWidth - 5 + 'px';
        }
        this.cdRef.detectChanges();
    };

    collapseOnGrouping = (): void => {
        if (this.dataOptions.groups && this.isShowTemplateForGroup || (this.dataOptions.detailTemplate && this.dataOptions.groupable && this.dataOptions.groups && this.dataOptions.groups.length === 0)) {
            this.collapseAll();
        }
    };

    displayContextMenu = (): void => {
        this.showContextMenu = this.dataOptions.groups && this.dataOptions.groups.length > 0 && !this.anyColumnLocked ? false : this.dataOptions.showContextMenu;
    };

    persistSelection(storeGridList: any): void {
        if (this._dataOptions.scrollableOptions && this._dataOptions.scrollableOptions.mode === scrollableMode.virtual) {
            this.allSelectedItem.filter(o1 => storeGridList.data.some(o2 => {
                if (o1[this.dataOptions.selectedRecords.rows.rowKeyField] === o2[this.dataOptions.selectedRecords.rows.rowKeyField]) {
                    o2.selected = true;
                }
            }));
        }
    }

    onDataBinding = (): void => {
        let storeGridList: any;
        storeGridList = this.wrapper.data;
        this.displayContextMenu();
        this.collapseOnGrouping();
        this.adjustGroupingColumns();
        const hasData = this.hasData();
        const hasGroups = !_.isEmpty(this.dataOptions.groups) && !this.anyColumnLocked;
        if (hasData && this._dataOptions.pageable && storeGridList.total >= 5) {
            this.wrapper.pageable = {
                ...this.defaultPageableSettings,
                ...(this._dataOptions.pageable === true ? {} : this._dataOptions.pageable)
            };
        } else if (this.wrapper.pageable) {
            this.wrapper.pageable = false;
        }

        if (this.initialDataLoded && !this._dataOptions.persistSelection) {
            this.gridSelectionHelper.rowSelection = [];
        }

        if (hasGroups) {
            this.wrapper.pageable = false;
        }

        this.initialDataLoded = true;

        if (this._dataOptions.onDataBound) {
            this._dataOptions.onDataBound(this.wrapper.data);
        }

        if (this._dataOptions.selectedRecords && this._dataOptions.selectedRecords.rows) {
            if (!this._dataOptions.selectable) {
                this._dataOptions.selectable = true;
            }

            if (this.wrapper.data) {
                const data = (this.wrapper.data as GridDataResult).data ? (this.wrapper.data as GridDataResult).data : this.wrapper.data as Array<any>;
                this.gridSelectionHelper.selectDeselectPage(data);
            }
        }
        this.persistEditingStates();

        this.dataBound.emit(this.wrapper.data);

        this.gridMessage = this.hasData() ? '' : this.noRecordMessage;

        if (this.focusRowIndexValue && this._dataOptions.navigable) {
            this.wrapper.focusCell(this.focusRowIndexValue + 1, 0);
        }
        this.persistSelection(storeGridList);
        storeGridList.total = storeGridList.total;
        this.totalRecord.emit(storeGridList.total);
        this.cdRef.detectChanges();
        this.resetPreview();
        this.removeGroupCells();
        setTimeout(this.manageBarWidth, 500);
    };

    removeGroupCells = (): void => {
        if (this.dataOptions.groups && this.dataOptions.groups.length > 0) {
            const groupCells = this.wrapper.wrapper.nativeElement.querySelectorAll('td.k-group-cell');
            if (groupCells.length > 0) {
                groupCells.forEach(gc => {
                    this.renderer.removeChild(this.wrapper.wrapper.nativeElement, gc);
                });
            }
        }

        this.cdRef.detectChanges();
    };

    adjustGroupingColumns = () => {
        if (!this.dataOptions.groupable) {
            return;
        }

        if (this.dataOptions.groupable && this.dataOptions.groups && this.dataOptions.groups.length === 0) {
            _.each(this.dataOptions.columns, (c: GridColumnDefinition) => {
                c.hidden = false;
            });
        }

        const groupFields = _.pluck(this.dataOptions.groups, 'field');
        const colsToHide = _.filter(this.dataOptions.columns, (c: GridColumnDefinition) => {
            return _.contains(groupFields, c.field);
        });
        _.each(colsToHide, (ch) => {
            ch.hidden = true;
        });

        const colsToUnHide = _.filter(this.dataOptions.columns, (c: GridColumnDefinition) => {
            return !_.contains(groupFields, c.field);
        });
        _.each(colsToUnHide, (ch) => {
            ch.hidden = false;
        });
    };

    readonly detailExpand = (event: any) => {
        const groupedRecords: any = this.applyGrouping(event);
        this.onDetailExpand.emit(groupedRecords);
    };

    applyGrouping = (childitem: any): any => {
        if (this.dataOptions.groups && this.dataOptions.groups.length > 1) {
            const storedValue = this.ipxGroupingService.groupedDataSet$.getValue();
            const currentChild = storedValue[childitem.index];
            const groupBy: any = _.without(this.dataOptions.groups, this.dataOptions.groups[0]);
            const groupResult = process(currentChild.items, { group: groupBy });
            const result = [];
            groupResult.data.forEach((item) => {
                result.push(this.ipxGroupingService.convertRecordForGrouping(item));
            });
            childitem.dataItem.items = result;
        }

        return childitem;
    };

    readonly detailCollapse = (event: Event) => {
        this.onDetailCollapse.emit(event);
    };

    private readonly persistEditingStates = (): void => {
        if (this._dataOptions.rowMaintenance && this._dataOptions.rowMaintenance.rowEditKeyField && (Object.keys(this._dataOptions.rowMaintenance).length > 0) || (this._dataOptions.rowMaintenance && this._dataOptions.rowMaintenance.rowEditKeyField && this._dataOptions.alwaysRenderInEditMode)) {
            const data = (this.wrapper.data as GridDataResult).data ? (this.wrapper.data as GridDataResult).data : this.wrapper.data as Array<any>;
            data.map((row, i) => {
                const key = String(row[this._dataOptions.rowMaintenance.rowEditKeyField]);
                if (this.rowEditFormGroups && this.rowEditFormGroups[key] && this.rowEditFormGroups[key].value.status !== rowStatus.Adding) {
                    row.status = this.rowEditFormGroups[key].value.status;
                    this.wrapper.editRow(this.wrapper.skip + i, this.rowEditFormGroups[key]);
                } else {
                    this.wrapper.closeRow(this.wrapper.skip + i);
                }

                if (this._dataOptions.alwaysRenderInEditMode && (this._dataOptions.rowMaintenance && this._dataOptions.rowMaintenance.rowEditKeyField)) {
                    this.rowEditHandler(event, i, data[i]);
                }

                if (row.status === rowStatus.deleting) {
                    this.deleteRowEvent.emit(row);
                }
            });

            if (this.rowEditFormGroups && this.wrapper.skip === 0) {
                Object.keys(this.rowEditFormGroups).forEach(x => {
                    if (this.rowEditFormGroups[x].value.status === rowStatus.Adding) {
                        const rowIndex = this.data.addRow(this._dataOptions.itemTemplate);
                        const dataItem = { status: rowStatus.Adding };
                        dataItem[this.dataOptions.rowMaintenance.rowEditKeyField] = x;

                        Object.assign(dataItem, this.rowEditFormGroups[x].value);
                        if (Array.isArray(this.wrapper.data)) {
                            this.wrapper.data[rowIndex] = dataItem;
                        } else {
                            (this.wrapper.data).data[rowIndex] = dataItem;
                        }
                        this.rowEditFormGroups = {
                            ...(this.rowEditFormGroups || {}), ...{ [String(dataItem[this.dataOptions.rowMaintenance.rowEditKeyField])]: this.rowEditFormGroups[x] }
                        };

                        this.wrapper.editRow(rowIndex, this.rowEditFormGroups[x]);
                        this._dataOptions.formGroup = this.rowEditFormGroups[x];
                    }
                });
            }
        }
    };

    checkChanged = (dataItem?: any): void => {
        this.allSelectedItem = this.gridSelectionHelper.checkChanged(dataItem, this.dataOptions, this.wrapper.data);
    };

    onMaintenanceAction = (value, action): void => {
        this.rowOnMaintnance.emit({ value, action });
    };

    onCellClick = ({ sender, dataItem, originalEvent, rowIndex, columnIndex, isEdited }): void => {
        originalEvent.preventDefault();
        this.clickedCellDetail = sender.activeCell;
        this.focusRowIndexValue = rowIndex;
        this.dataItemClicked.emit(dataItem);
        if (this.autoApplySelection) {
            dataItem.selected = !dataItem.selected;
            this.checkChanged(dataItem);
        }

        this.cdRef.markForCheck();
    };

    onDbClick(event): void {
        this.onCellDbClick.emit(this.clickedCellDetail);
    }

    resetPreview = (): void => {
        if (this.showPreview) {
            const selectedRow = this.wrapper.wrapper.nativeElement.querySelectorAll('tr.k-state-selected')[0];
            if (selectedRow) {
                this.renderer.removeClass(selectedRow, 'k-state-selected');
                this.renderer.removeClass(selectedRow, 'selected');
            }

            this.dataItemClicked.emit({ caseKey: null, rowKey: -1 });
            this.focusRowIndexValue = null;
            this.cdRef.detectChanges();
        }
    };

    showMenu = (event: any, dataItem: any, rowIndex: any): void => {
        if (!this.enableTaskMenu(dataItem)) { return; }
        this.taskMenuDataItem = {
            ...dataItem, ...{ _rowIndex: rowIndex }
        };
        this.popupOpen.emit(this.taskMenuDataItem);
        if (this.gridContextMenu) {
            this.gridContextMenu.show({ left: event.pageX, top: event.pageY });
            this.cdRef.detectChanges();
        }

        return;
    };
    onMenuItemSelected = (event: MenuEvent): void => {
        if (event.item && event.item.rowMaintenanceItem) {
            event.item.action(null, this.taskMenuDataItem._rowIndex, this.taskMenuDataItem);

            return;
        }
        this.menuItemSelected.emit({ event, dataItem: this.taskMenuDataItem });
    };
    getRowMaintenanceMenuItems = (dataItem: any): Array<any> => {

        const taskItems = [];
        if (this.rowMaintenance) {
            if (this.showEditButton(dataItem, this.rowMaintenance)) {
                taskItems.push({
                    id: 'edit',
                    text: 'Edit',
                    icon: 'cpa-icon cpa-icon-pencil-square-o',
                    action: this.rowEditHandler,
                    rowMaintenanceItem: true
                });
            }
            if (this.showRevertButton(dataItem, this.rowMaintenance)) {
                taskItems.push({
                    id: 'revert',
                    text: 'Revert',
                    icon: 'cpa-icon cpa-icon-revert',
                    action: this.rowCancelHandler,
                    rowMaintenanceItem: true
                });
            }
            if (dataItem && this.rowMaintenance.canDuplicate) {
                taskItems.push({
                    id: 'duplicate',
                    text: 'Duplicate',
                    icon: 'cpa-icon cpa-icon-files-o',
                    action: this.rowDuplicateHandler,
                    rowMaintenanceItem: true
                });
            }
            if (this.showDeleteButton(dataItem, this.rowMaintenance)) {
                taskItems.push({
                    id: 'delete',
                    text: 'Delete',
                    icon: 'cpa-icon cpa-icon-trash',
                    action: this.rowDeleteHandler,
                    rowMaintenanceItem: true
                });
            }
        }

        return taskItems;
    };

    toggleSelectAll(): void {
        const data: Array<any> = this.getCurrentData();
        data.forEach((dataItem) => dataItem.selected = this.gridSelectionHelper.isSelectAll);
        this.cdRef.markForCheck();
        this.checkChanged();
    }

    markActive = (item: any): void => {
        this.activeTaskMenuItems = [];
        this.updateActiveTaskItems(item);
    };

    private readonly updateActiveTaskItems = (item): void => {
        this.activeTaskMenuItems.push(item.id);
        if (item.parent) {
            this.updateActiveTaskItems(item.parent);
        }
    };

    isTaskItemActive = (itemId: string): boolean => {
        return _.some(this.activeTaskMenuItems, (key: string) => {
            return key === itemId;
        });
    };

    selectAllPage(): void {
        this.gridSelectionHelper.selectAllPage(this.wrapper.data);
        this.cdRef.markForCheck();
        this.checkChanged();
    }

    clearSelection(): void {
        this.gridSelectionHelper.deselectAllPage(this.wrapper.data);
        if (this._dataOptions.onClearSelection) {
            this._dataOptions.onClearSelection();
        }
        this.cdRef.markForCheck();
        this.checkChanged();
    }

    resetSelection(): void {
        this.gridSelectionHelper.resetSelection();
    }

    getSelectedItems(columnId: string): Array<any> {
        return _.any(this.gridSelectionHelper.allSelectedItems) ? _.pluck(this.gridSelectionHelper.allSelectedItems, columnId)
            : this.gridSelectionHelper.allSelectedIds;
    }

    hasItemsSelected(): boolean {
        return _.any(this.gridSelectionHelper.rowSelection);
    }

    getRowSelectionParams(): {
        isAllPageSelect: boolean, allSelectedItems: Array<any>, rowSelection: Array<any>, allDeSelectIds: Array<number>, allDeSelectedItems: Array<any>,
        singleRowSelected$: BehaviorSubject<boolean>
    } {
        return {
            isAllPageSelect: this.gridSelectionHelper.isAllPageSelect,
            allSelectedItems: this.gridSelectionHelper.allSelectedItems,
            rowSelection: this.gridSelectionHelper.rowSelection,
            allDeSelectIds: this.gridSelectionHelper.allDeSelectIds,
            allDeSelectedItems: this.gridSelectionHelper.allDeSelectedItems,
            singleRowSelected$: this.gridSelectionHelper.singleRowSelected$
        };
    }

    collapseAll = (rowIndex?: number): void => {
        if (rowIndex) {
            this.wrapper.collapseRow(rowIndex);

            return;
        }
        const data: Array<any> = this.getCurrentData();
        data.forEach((item, index) => {
            this.wrapper.collapseRow(this.wrapper.skip + index);
        });
    };

    closeEditedRows = (skip): void => {
        const data = (this.wrapper.data as GridDataResult).data ? (this.wrapper.data as GridDataResult).data : this.wrapper.data as Array<any>;
        data.map((row, i) => {
            if (row) {
                const key = String(row[this._dataOptions.rowMaintenance.rowEditKeyField]);
                if (this.rowEditFormGroups && this.rowEditFormGroups[key]) {
                    this.wrapper.closeRow(skip + i);
                    this.wrapper.closeRow(i);
                }
            }
        });
        this.cdRef.detectChanges();
    };

    readonly search = (): void => {
        if (!this.isready) { return; }
        this.wrapper.skip = 0;
        this.initialDataLoded = false;

        if (this._dataOptions.manualOperations) {
            this.gridSelectionHelper.ClearSelection();
            this.data.bindOneTimeData();

            return;
        }
        this.data.selectPage(0);
    };

    readonly clear = (): void => {
        if (!this.isready) { return; }
        this.data.clear();
        this.setInitialText();
        this.cdRef.markForCheck();
    };

    private readonly setInitialText = (): void => {
        this.gridMessage = this.performSearchMessage;
    };

    private readonly preventDefault = (event: KeyboardEvent): void => {
        event.stopPropagation();
        event.preventDefault();
    };

    private readonly caliberateIndex = (newVal: number): void => {
        this.focusRowIndexValue = (this.wrapper.activeCell && this.wrapper.activeCell.dataRowIndex >= 0 && this.wrapper.activeCell.dataRowIndex !== newVal) ? this.wrapper.activeCell.dataRowIndex : newVal;
    };

    private readonly selectPage = (index: number): void => {
        this.wrapper.skip = this.wrapper.pageSize * (index - 1);
        this.data.selectPage(this.wrapper.skip);

        if (this.dataOptions.showExpandCollapse) {
            this.expandCollapseAll(true);
        }
    };

    private readonly selectRows = (rowKeyField: string, selectedKeys: Array<any>): void => {
        this.gridSelectionHelper.rowSelectionKey = rowKeyField;
        this.gridSelectionHelper.rowSelection = selectedKeys;
    };

    private readonly unSupported = (): string => {
        // if (this._dataOptions.filterable !== undefined) { return 'Filters are not currently supported'; }

        return '';
    };

    // tslint:disable-next-line: cyclomatic-complexity
    private setOptions(): void {
        if (this.dataOptions.groupable) {
            const anyColumnLocked = this.gridHelper.isAnyColumnLokced(this._dataOptions);
            if (anyColumnLocked) {
                this.dataOptions.groupable = false;
                this.dataOptions.groups = undefined;
            }
        }
        if (this.dataOptions.groupable) {
            this.dataOptions.groupable = {
                emptyText: this.translate.instant('grid.messages.groupHeading')
            };
        }

        if (this._dataOptions.filterable === true) {
            this._dataOptions.filterable = 'menu';
        }

        if (this._dataOptions.showGridMessagesUsingInlineAlert === undefined) {
            this._dataOptions.showGridMessagesUsingInlineAlert = true;
        }

        if (this._dataOptions.gridMessages === undefined) {
            this._dataOptions.gridMessages = {};
        }

        if (this._dataOptions.navigable === undefined) {
            this._dataOptions.navigable = true;
        }

        if (this._dataOptions.sortable as Boolean !== undefined) {
            this._dataOptions.sortable = {
                mode: 'single'
            };
        }

        if (this._dataOptions.pageable) {
            this.pageable = {
                ...this.defaultPageableSettings,
                ...(this._dataOptions.pageable === true ? {} : this._dataOptions.pageable)
            };
            this.setPageSizeFromLocalStorage();
        }

        if (this._dataOptions.autobind === undefined) {
            this._dataOptions.autobind = true;
        }

        if (this._dataOptions.selectedRecords) {
            if (this._dataOptions.selectedRecords.page) {
                this._dataOptions.autobind = false;
                this.performActionsAfterViewInit.push(() => {
                    this.selectPage(this._dataOptions.selectedRecords.page);
                    this._dataOptions.selectedRecords = undefined;
                });
            }
            if (this._dataOptions.selectedRecords.rows) {
                if (!this._dataOptions.selectable) {
                    this._dataOptions.selectable = true;
                }
                this.gridSelectionHelper.rowSelectionKey = this._dataOptions.selectedRecords.rows.rowKeyField;
                this.gridSelectionHelper.rowSelection = this._dataOptions.selectedRecords.rows.selectedKeys;
            }
        }

        if (!this._dataOptions.rowClass) {
            this._dataOptions.rowClass = this.rowCallBack;
        }

        if (this._dataOptions.canAdd || this.rowMaintenance) {
            this.itemName = this._dataOptions.itemName ? this.translate.instant(this._dataOptions.itemName) : this.translate.instant('grid.messages.defaultItemName');
        }

        if (this.rowMaintenance && this._dataOptions.canAdd) {
            // Kendogrid not able to add new row to top while other rows are editing mode, add to bottom instead
            this._dataOptions.addRowToTheBottom = true;
        }

        if (this._dataOptions.showContextMenu) {
            this.showContextMenu = true;
        }

        if (!this._dataOptions.autobind) {
            this.setInitialText();
        }

        const anyColumnLocked = this.gridHelper.isAnyColumnLokced(this._dataOptions);
        if (anyColumnLocked) {
            this.performActionsAfterViewInit.push(() => {
                this.calcScrollableDivWidth();
            });
        }

        this._dataOptions.columns.filter(f => f.filter && f.defaultFilters && f.defaultFilters.length > 0).forEach(c => {
            const dataState: State = (this.data as any).state;
            if (!dataState.filter) {
                dataState.filter = { logic: 'and', filters: [] };
            }
            dataState.filter.filters.push({
                logic: 'and',
                filters: [{
                    field: c.field,
                    operator: 'in',
                    value: c.defaultFilters.join(',')
                }]
            });
        });
    }

    private readonly setPageSizeFromLocalStorage = () => {
        const pageable = (this._dataOptions.pageable as PageSettings);
        if (pageable) {
            if (pageable.pageSizeSetting !== undefined) {
                this.pageSize = pageable.pageSizeSetting.getLocal;
            } else if (pageable.pageSize !== undefined) {
                this.pageSize = pageable.pageSize;
            }
            this.wrapper.pageSize = this.pageSize;
        }
    };

    calcScrollableDivWidth = (): void => {
        if (this.wrapper) {
            const element = this.wrapper.wrapper.nativeElement;
            let gridEle = element.getElementsByTagName('kendo-grid-list')[0];
            const gridUnlockedHeaderEle = element.getElementsByClassName(
                'k-grid-header-wrap'
            )[0];
            const lockedGridEle = element.getElementsByClassName(
                'k-grid-content-locked'
            )[0];
            if (gridEle.clientWidth === 0) {
                gridEle = element.getElementsByClassName('k-grid-header')[0];
            }
            const gridElementWidth = document.documentElement.getElementsByClassName('ipx-topics').length > 0 ? gridEle.clientWidth - 20 : gridEle.clientWidth;
            const lockedGridWidth = lockedGridEle ? (lockedGridEle.clientWidth === 0 ? lockedGridEle.offsetWidth : lockedGridEle.clientWidth) : 0;
            const unlockedGridWidth = gridElementWidth - lockedGridWidth;
            const scrollableElement = element.getElementsByClassName(
                'k-grid-content k-virtual-content'
            )[0];
            this.renderer.setStyle(lockedGridEle, 'margin-left', '8px');
            this.renderer.setStyle(
                scrollableElement,
                'width',

                unlockedGridWidth.toString() + 'px'
            );
            this.renderer.setStyle(
                gridUnlockedHeaderEle,
                'width',
                unlockedGridWidth.toString() + 'px'
            );
        }
    };

    private hasData(): boolean {
        return this.getCurrentData().length > 0;
    }

    getCurrentData(): Array<any> {
        const data: any = this.wrapper.data;
        if (data) {

            return (data as GridDataResult).data ? (data as GridDataResult).data : data as Array<any>;
        }

        return [];
    }

    getExistingSelectedData(): Array<{ dataItem: any, index: number }> {
        return this.getCurrentData().map((item, index) => ({ dataItem: item, index })).filter((item) => item.dataItem.selected);
    }

    restoreSavedGroupOnRefresh(): void {
        this.storeGroupsForRefresh = this.dataOptions.groups ? this.dataOptions.groups.length ? this.dataOptions.groups.map(x => ({ ...x })) : [] : [];
    }

    clearFilters(): void {
        this.data.filter = {
            logic: 'and',
            filters: []
        };

    }
    onReorder(event: ColumnReorderEvent): void {
        let newIndex = this.showContextMenu ? event.newIndex - 1 : event.newIndex;
        if (newIndex < event.oldIndex && this.minReorderIndex != null && newIndex <= this.minReorderIndex) {
            event.preventDefault();

            return;
        }

        const column = this._dataOptions.columns.filter((c) => { return c.field === (event.column as ColumnComponent).field; });
        if (column && column[0].fixed) {
            event.preventDefault();

            return;
        }

        let fromLocal = this._dataOptions.columnSelection ? this._dataOptions.columnSelection.localSetting.getLocal : null;
        const defaultColumns = _.map(this._dataOptions.columns, (col: any, index) => {

            return { field: col.field, hidden: col.hidden || false, title: col.title, index };
        });
        if (!!fromLocal && defaultColumns.length > fromLocal.length) {
            fromLocal = [...defaultColumns.filter(c => c.title === ''), ...fromLocal];
        }
        const savedOrDefaultColumns = (fromLocal || defaultColumns);
        const unHiddenCols = savedOrDefaultColumns.filter(c => !c.hidden);
        if (unHiddenCols.length === newIndex) {
            newIndex = newIndex - 1;
        }
        const fieldToPlaceBefore = unHiddenCols[newIndex].field;
        const sourceIndex = (savedOrDefaultColumns).findIndex(c => c.field === (event.column as any).field);
        const targetIndex = (savedOrDefaultColumns).findIndex(c => c.field === fieldToPlaceBefore);
        const srcElem = savedOrDefaultColumns[sourceIndex];
        const newColumns = _.without(savedOrDefaultColumns, srcElem);
        newColumns.splice(targetIndex, 0, srcElem);

        // save to local settings
        if (this._dataOptions.columnSelection) {
            this._dataOptions.columnSelection.localSetting.setLocal(_.map(newColumns, (col: any, index) => {

                return { field: col.field, hidden: col.hidden || false, index };
            }));
        }
    }

    onSort(sort: Array<SortDescriptor>): void {
        this.gridSelectionHelper.ClearSelection(true);
        if (this._dataOptions.manualOperations) {
            if (this.wrapper.data as GridDataResult && !!(this.wrapper.data as GridDataResult).data) {
                this._gridTotal = (this.wrapper.data as GridDataResult).total;
                this.wrapper.data = { data: orderBy(this.allItems, sort).slice(this.wrapper.skip, this.wrapper.skip + this.wrapper.pageSize), total: this._gridTotal };
            } else {
                this.wrapper.data = orderBy(this.wrapper.data as Array<any>, sort);
            }
        }
    }

    groupValue(value: any): string {
        if (typeof value === 'object') {
            return value.value;
        }

        return value;
    }

    private get pageLocalSetting(): LocalSetting {
        const pageable = (this._dataOptions.pageable as PageSettings);

        return pageable && pageable.pageSizeSetting !== undefined ? pageable.pageSizeSetting : undefined;
    }

    private get noRecordMessage(): string {
        return this._dataOptions.gridMessages.noResultsFound === undefined ? 'noResultsFound' : this._dataOptions.gridMessages.noResultsFound;
    }

    private get performSearchMessage(): string {
        return this._dataOptions.gridMessages.performSearch === undefined ? 'performSearchHint' : this._dataOptions.gridMessages.performSearch;
    }

    private get isready(): boolean {
        return Boolean(this.dataOptions);
    }

    enableTaskMenu = (dataitem: any): Boolean => {

        let isEditable = true;
        if (dataitem && dataitem.isEditable === false) {
            isEditable = dataitem.isEditable;
        }

        return this._dataOptions.enableTaskMenu && isEditable;
    };
}

export enum rowStatus {
    editing = 'E',
    deleting = 'D',
    Adding = 'A'
}

export enum scrollableMode {
    scrollable = 'scrollable',
    virtual = 'virtual',
    none = 'none'
}