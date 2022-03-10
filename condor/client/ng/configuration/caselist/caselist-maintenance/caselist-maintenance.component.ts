import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxPicklistMaintenanceService } from 'shared/component/typeahead/ipx-picklist/ipx-picklist-maintenance.service';
import * as _ from 'underscore';
import { CaseListViewData } from '../caselist-data';
import { CaselistMaintenanceService } from '../caselist-maintenance.service';
import { CaselistModalComponent } from '../caselist-modal/caselist-modal.component';

@Component({
  selector: 'app-caselist-maintenance',
  templateUrl: './caselist-maintenance.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaselistMaintenanceComponent implements OnInit {
  gridOptions: IpxGridOptions;
  searchText: string;
  headerText: string;
  caseListModalRef: BsModalRef;
  selectedRowKey: number;
  @Input() viewData: CaseListViewData;
  actionDelete: IpxBulkActionOptions;
  newlyAddedCaselistKeys: Array<number> = [];
  cannotDeleteCaselistKeys: Array<number> = [];

  @ViewChild('caselistMaintenanceGrid', { static: true }) caselistGrid: IpxKendoGridComponent;
  constructor(private readonly translate: TranslateService,
    private readonly notificationService: NotificationService,
    private readonly caselistMaintenanceService: CaselistMaintenanceService,
    private readonly ipxMaintenanceService: IpxPicklistMaintenanceService,
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly modalService: IpxModalService) { }

  ngOnInit(): void {
    this.headerText = this.translate.instant('picklist.caselist.caselistMaintenance');
    this.searchText = '';
    this.initBulkActionItems();
    this.gridOptions = this.buildGridOptions();
  }

  search(cannotDeleteCaseListKeys: Array<number> = [], newlyAddedCaseListKeys: Array<number> = []): void {
    this.cannotDeleteCaselistKeys = cannotDeleteCaseListKeys;
    this.newlyAddedCaselistKeys = newlyAddedCaseListKeys;
    this.gridOptions._search();
  }

  clear(): void {
    this.searchText = '';
    this.cannotDeleteCaselistKeys = [];
    this.newlyAddedCaselistKeys = [];
    this.gridOptions._search();
  }
  dataItemClicked = event => {
    const selected = event;
    this.selectedRowKey = selected ? selected.key : undefined;
  };

  private buildGridOptions(): IpxGridOptions {
    this.caselistGrid.rowSelectionChanged.subscribe((event) => {
      if (this.actionDelete) {
        this.actionDelete.enabled = this.viewData.permissions.canDeleteCaseList && event.rowSelection.length > 0;
      }
    });

    return {
      sortable: true,
      selectable: {
        mode: 'multiple'
      },
      onDataBound: (data: any) => {
        this.caselistGrid.getRowSelectionParams().allSelectedItems = [];
        this.caselistGrid.getRowSelectionParams().rowSelection = [];
        this.caselistGrid.getRowSelectionParams().allDeSelectIds = [];
      },
      customRowClass: (context) => {
        let returnValue = '';
        if (context.dataItem && context.dataItem.key === this.selectedRowKey) {
          returnValue += 'k-state-selected selected';
        }

        if (context.dataItem && this.newlyAddedCaselistKeys && this.newlyAddedCaselistKeys.length > 0 && this.newlyAddedCaselistKeys.indexOf(context.dataItem.key) !== -1) {
          returnValue += ' saved';
        }
        if (context.dataItem && this.cannotDeleteCaselistKeys && this.cannotDeleteCaselistKeys.length > 0 && this.cannotDeleteCaselistKeys.indexOf(context.dataItem.key) !== -1) {
          returnValue += ' error';
        }

        return returnValue;
      },
      read$: (queryParams) => this.getGridData(queryParams, this.searchText),
      columns: [{
        field: 'value', title: 'picklist.caselist.caseList', template: true
      }, {
        field: 'description', title: 'picklist.caselist.description'
      }, {
        field: 'primeCaseName', title: 'picklist.caselist.primeCase'
      }],
      bulkActions: [this.actionDelete],
      selectedRecords: { rows: { rowKeyField: 'key', selectedKeys: [] } }
    };
  }

  // tslint:disable-next-line: prefer-function-over-method
  private getGridData(queryParams: GridQueryParameters, searchText: string): any {
    queryParams.take = null;

    const criteria = {
      search: searchText,
      mode: 'maintenance'
    };

    return this.ipxMaintenanceService.getItems$('api/picklists/CaseLists', criteria, queryParams, false);
  }

  private readonly deleteCaseLists = (): void => {
    const selectedCaseListIds = this.caselistGrid.getSelectedItems('key');

    this.caselistMaintenanceService.deleteList(selectedCaseListIds).subscribe((response: { result?: string, errors?: Array<any>, cannotDeleteCaselistIds?: Array<number> }) => {
      if (response) {
        if (response.errors) {
          this.ipxNotificationService.openAlertModal('', '', response.errors.map((e) => e.message));
        } else if (response.result === 'success') {
          this.notificationService.success();
          this.search();
        } else if (response.result === 'partialComplete') {
          this.ipxNotificationService.openAlertModal('modal.partialComplete', ' ', [this.translate.instant('modal.alert.partialComplete'), this.translate.instant('modal.alert.alreadyInUse')]);
          this.search(response.cannotDeleteCaselistIds);
        } else if (response.result === 'error') {
          this.ipxNotificationService.openAlertModal('modal.unableToComplete', this.translate.instant('modal.alert.alreadyInUse'));
          this.search(response.cannotDeleteCaselistIds);
        }
      }
    });
  };

  openCaseListModal = (dataItem: any): void => {
    const initialState = {
      caseList: dataItem
    };
    this.caseListModalRef = this.modalService.openModal(CaselistModalComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState
    });
    this.caseListModalRef.content.onClose$.subscribe(
      (response) => {
        if (response === true || !_.isEmpty(response)) {
          if (response.newlyAddedCaselistKey || response.newlyAddedCaselistKey === 0) {
            this.newlyAddedCaselistKeys.push(response.newlyAddedCaselistKey);
          }
          this.search([], this.newlyAddedCaselistKeys);
          if (response.addAnother) {
            this.openCaseListModal(null);
          } else {
            this.notificationService.success();
          }
        }
      }
    );
  };

  private readonly initBulkActionItems = () => {

    this.actionDelete = {
      ...new IpxBulkActionOptions(),
      id: 'delete',
      icon: 'cpa-icon cpa-icon-trash',
      text: 'picklist.caselist.delete',
      enabled: false,
      click: () => {
        this.notificationService.confirmDelete({
          message: 'modal.confirmDelete.message'
        }).then(() => {
          this.deleteCaseLists();
        });
      }
    };
  };

}
