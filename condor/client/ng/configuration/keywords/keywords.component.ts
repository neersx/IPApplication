import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { BehaviorSubject, Subscription } from 'rxjs';
import { takeWhile } from 'rxjs/operators';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { KeywordsPermissions } from './keywords.model';
import { KeywordsService } from './keywords.service';
import { MaintainKeywordsComponent } from './maintain-keywords/maintain-keywords.component';

@Component({
  selector: 'ipx-keywords',
  templateUrl: './keywords.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [
    slideInOutVisible
  ]
})
export class KeywordsComponent implements OnInit, OnDestroy {
  gridOptions: IpxGridOptions;
  searchText: string;
  showSearchBar = true;
  deleteSubscription: Subscription;
  addedRecordId: number;
  actions: Array<IpxBulkActionOptions>;
  @Input() viewData: KeywordsPermissions;
  maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
  @ViewChild('columnTemplate', { static: false }) template: any;
  _resultsGrid: any;
  @ViewChild('ipxKendoGridRef') set resultsGrid(grid: IpxKendoGridComponent) {
    if (grid && !(this._resultsGrid === grid)) {
      if (this._resultsGrid) {
        this._resultsGrid.rowSelectionChanged.unsubscribe();
      }
      this._resultsGrid = grid;
      this.subscribeRowSelectionChange();
    }
  }

  constructor(private readonly service: KeywordsService,
    readonly localSettings: LocalSettings,
    private readonly modalService: IpxModalService,
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly notificationService: NotificationService) {
  }

  ngOnInit(): void {
    this.actions = this.initializeMenuActions();
    this.gridOptions = this.buildGridOptions();
  }

  private readonly subscribeRowSelectionChange = () => {
    this._resultsGrid.rowSelectionChanged.subscribe((event) => {
      const edit = this.actions.find(x => x.id === 'edit');
      if (edit) {
        edit.enabled = event.rowSelection.length === 1;
      }
      const bulkDelete = this.actions.find(x => x.id === 'delete');
      if (bulkDelete) {
        bulkDelete.enabled = event.rowSelection.length > 0;
      }
    });
  };

  private initializeMenuActions(): Array<IpxBulkActionOptions> {

    const menuItems: Array<IpxBulkActionOptions> = [];

    if (this.viewData.canEdit) {
      menuItems.push(
        {
          ...new IpxBulkActionOptions(),
          id: 'edit',
          icon: 'cpa-icon cpa-icon-edit',
          text: 'keywords.editKeyword',
          enabled: false,
          click: this.editKeywords
        }
      );
    }

    if (this.viewData.canDelete) {
      menuItems.push(
        {
          ...new IpxBulkActionOptions(),
          id: 'delete',
          icon: 'cpa-icon cpa-icon-trash',
          text: 'bulkactionsmenu.delete',
          enabled: false,
          click: this.deleteKeywordsConfirmation
        }
      );
    }

    return menuItems;
  }

  editKeywords = (resultGrid: IpxKendoGridComponent) => {
    const selectedRowKey = resultGrid.getRowSelectionParams().rowSelection[0];
    this.onRowAddedOrEdited(selectedRowKey, 'E');
  };

  deleteKeywordsConfirmation = (resultGrid: IpxKendoGridComponent): void => {
    const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('modal.confirmDelete.message', null);
    notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
      .subscribe(() => {
        const rowSelectionParams = resultGrid.getRowSelectionParams();
        let allKeys = [];
        if (rowSelectionParams.isAllPageSelect) {
          const deselectedRowKeys = _.pluck(resultGrid.getRowSelectionParams().allDeSelectedItems, 'keywordNo');
          const dataRows = Array.isArray(this._resultsGrid.wrapper.data) ? this._resultsGrid.wrapper.data
            : (this._resultsGrid.wrapper.data).data;
          allKeys = _.pluck(dataRows, 'keywordNo');
        } else {
          allKeys = _.map(resultGrid.getRowSelectionParams().allSelectedItems, 'keywordNo');
        }
        if (allKeys.length > 0) {
          this.deleteKeywords(allKeys);
        }
      });
  };

  deleteKeywords = (allKeys: Array<number>): void => {
    this.service.deleteKeywords(allKeys).subscribe(() => {
      this.notificationService.success();
      this._resultsGrid.clearSelection();
      this.gridOptions._search();
    });
  };

  ngOnDestroy(): void {
    if (!!this.deleteSubscription) {
      this.deleteSubscription.unsubscribe();
    }
  }

  buildGridOptions(): IpxGridOptions {

    return {
      autobind: true,
      navigable: true,
      sortable: true,
      reorderable: true,
      pageable: {
        pageSizes: [5, 10, 20, 50],
        pageSizeSetting: this.localSettings.keys.keywords.pageSize
      },
      read$: (queryParams) => {

        return this.service.getKeywordsList({ text: this.searchText }, queryParams);
      },
      rowMaintenance: {
        rowEditKeyField: 'keywordNo'
      },
      bulkActions: (this.viewData.canEdit || this.viewData.canDelete) ? this.actions : null,
      selectedRecords: {
        rows: {
          rowKeyField: 'keywordNo',
          selectedKeys: []
        }
      },
      customRowClass: (context) => {
        let returnValue = '';
        if (context.dataItem && context.dataItem.keywordNo === this.addedRecordId) {
          returnValue += ' saved k-state-selected selected';
        }

        return returnValue;
      },
      selectable: (this.viewData.canEdit || this.viewData.canDelete) ? {
        mode: 'multiple'
      } : false,
      enableGridAdd: this.viewData.canAdd,
      columns: this.getColumns()
    };
  }

  onRowAddedOrEdited(data: any, state: string): void {
    const modal = this.modalService.openModal(MaintainKeywordsComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState: {
        id: data,
        isAdding: state === rowStatus.Adding
      }
    });
    modal.content.onClose$.subscribe(
      (event: any) => {
        this.onCloseModal(event);
      }
    );

    modal.content.addedRecordId$.subscribe(
      (event: any) => {
        this.addedRecordId = event;
      }
    );
  }

  onCloseModal(event): void {
    if (event) {
      this.notificationService.success();
      this.gridOptions._search();
    }
  }

  search(): void {
    this._resultsGrid.clearSelection();
    this.gridOptions._search();
  }

  clear(): void {
    this.searchText = '';
    this._resultsGrid.clearSelection();
    this.gridOptions._search();
  }

  getColumns = (): Array<GridColumnDefinition> => {
    const columns: Array<GridColumnDefinition> = [{
      title: 'keywords.column.keyword',
      field: 'keyWord',
      sortable: true,
      template: true
    }, {
      title: 'keywords.column.caseStopWord',
      field: 'caseStopWord',
      template: true
    }, {
      title: 'keywords.column.nameStopWord',
      field: 'nameStopWord',
      template: true
    }];

    return columns;
  };
}
