import { TemplateRef } from '@angular/core';
import { FormArray, FormGroup } from '@angular/forms';
import { RowClassFn, SelectableSettings, SortSettings } from '@progress/kendo-angular-grid';
import { GroupDescriptor, SortDescriptor } from '@progress/kendo-data-query';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BehaviorSubject, Observable } from 'rxjs';
import { IpxBulkActionOptions } from './bulkactions/ipx-bulk-actions-options';
import { ColumnSelection, GridColumnDefinition, GridMessages, GridPagableData, GridQueryParameters, MaintenanceMetaData, PageSettings } from './ipx-grid.models';

export type IpxGridOptions = {
  columns: Array<GridColumnDefinition>;
  selectable?: boolean | SelectableSettings;
  sortable?: boolean | SortSettings;
  pageable?: boolean | PageSettings;
  scrollableOptions?: { mode?: string, rowHeight?: number, height?: number };
  navigable?: boolean;
  hideHeader?: boolean | false;
  filterable?: boolean | 'menu';
  /**
   * Specifies if Read function should be called automatically on load
   * @default true
   */
  autobind?: boolean;
  reorderable?: boolean;
  columnPicker?: boolean;
  persistSelection?: boolean;
  rowMaintenance?: {
    canEdit?: boolean,
    canDelete?: boolean
    rowEditKeyField?: string;
    canDuplicate?: boolean;
    width?: string;
    hideButtons?: boolean,
    /**
     * Sets the resource-id for a custom tooltip for the Delete icon
     * If not set, tooltip is set to 'Delete' resource string
     */
    deleteTooltip?: string;
    editTooltip?: string;
  };
  picklistCanMaintain?: boolean;
  maintainanceMetaData$?: BehaviorSubject<MaintenanceMetaData>;
  read$(
    queryParams: GridQueryParameters
  ): Observable<Array<any> | GridPagableData>;
  detailTemplate?: TemplateRef<any>;
  groupDetailTemplate?: TemplateRef<any>;
  /**
   * Default is to always show
   * @default true
   */
  detailTemplateShowCondition?(dataItem: any, index: number): boolean;
  showExpandCollapse?: boolean;
  filterMetaData$?(column: any, otherFilters: any): Observable<Array<any>>;
  /**
   * A function that is executed for each row to add classes to row
   * @RowClassFn (context: RowClassArgs) => string | string[] | Set<string> | { [key: string]: any }
   * @RowClassArgs context is an object {dataItem : any, index : number }
   */
  rowClass?: RowClassFn;
  customRowClass?: RowClassFn;
  dimRowsColumnName?: string;
  columnSelection?: ColumnSelection;
  _search?(): void;
  _refresh?(): void;
  onDataBound?(data: any): void;
  onClearSelection?(): void;
  selectedRecords?: { page?: number, rows?: { rowKeyField: string, selectedKeys: Array<any>, selectedRecords?: Array<any> } };
  _selectPage?(index: number): void;
  _selectRows?(rowKeyField: string, selectedKeys: Array<any>): void;
  canAdd?: boolean;
  gridAddDelegate?(): void;
  itemName?: string;
  createFormGroup?(dataItem?: any): FormGroup;
  formGroup?: FormGroup;
  formGroupArray?: FormArray;
  maintainFormGroup$?: BehaviorSubject<FormGroup>;
  itemTemplate?: any;
  /**
   * Object for defining grid messages.
   * @Note If a message is not set, default will be used by the grid. If you dont want to show a message set it as ''
   */
  gridMessages?: GridMessages;
  /**
   * Show the grid messages like perform search and no records found using an inline alert (blue border)
   * @default true
   */
  resetGridSelectionOnDataBind?: boolean;
  showGridMessagesUsingInlineAlert?: boolean;
  // expandRowOnAdd?: boolean;
  enableGridAdd?: boolean;
  // canRowBeAdded?: boolean;
  _closeEditMode?(): void;
  bulkActions?: Array<IpxBulkActionOptions>;
  navigateByIndex?(index: number): void;
  addRowToTheBottom?: boolean;
  editRow?(rowIdx: number, dataItem: any, editDetails?: boolean): void;
  removeRow?(rowIdx?: number): void;
  addOnSave?(): void;
  draggable?: boolean;
  showContextMenu?: boolean;
  /**
   * When set to true, provides manual handling of data opertions like sort, page change etc through events.
   * Note: if set to true then changing page size would not automatically trigger data refresh from the data directive
   */
  manualOperations?: boolean | false;
  sort?: Array<SortDescriptor>
  groupable?: any;
  groups?: Array<GroupDescriptor>;
  onDataItemCheckboxSelection?(dataItem: any, data: Array<any>): void;
  enableTaskMenu?: Boolean;
  alwaysRenderInEditMode?: boolean;
  disableMultiRowEditing?: boolean;
  hasDisabledRows?: boolean;
  hideExtraBreakInGrid?: boolean;
};
