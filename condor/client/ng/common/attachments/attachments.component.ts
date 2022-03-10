import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { race } from 'rxjs';
import { filter, map, take, takeUntil, takeWhile } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition, TaskMenuItem } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { HideEvent, IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { AttachmentMaintenanceComponent } from './attachment-maintenance/attachment-maintenance.component';
import { AttachmentService } from './attachment.service';

@Component({
  selector: 'ipx-attachments',
  templateUrl: './attachments.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class AttachmentsComponent implements OnInit {
  _caseKey: number;
  _caseIrn: string;
  postPerformed: any;
  @Input() dataModified: boolean;
  @Output() readonly dataModifiedChange = new EventEmitter<boolean>();

  @Input() viewData: { isExternal: boolean, canMaintainAttachment: { canAdd: boolean, canEdit: boolean, canDelete: boolean }, baseType: 'case' | 'name' | 'activity' | 'priorArt', key: number };
  @Input() set caseDetails(caseDetails: any) {
    if (!!caseDetails) {
      this._caseKey = caseDetails.key;
      this._caseIrn = caseDetails.code;
      if (this.gridOptions) {
        this.gridOptions._search();
      }
    }
  }
  @Input() eventDetails: {
    eventKey: number;
    eventCycle: number;
    actionKey: string
  };
  @ViewChild('grid', { static: true }) grid: IpxKendoGridComponent;
  topic: Topic;
  modalRef: BsModalRef;
  gridOptions: IpxGridOptions;
  taskItems: Array<TaskMenuItem>;

  baseType: 'case' | 'name' | 'activity' | 'priorArt';
  canMaintainAttachments: boolean;

  constructor(private readonly service: AttachmentService,
    private readonly modalService: IpxModalService,
    readonly localSettings: LocalSettings,
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly notificationService: NotificationService,
    private readonly destroy$: IpxDestroy) { }

  ngOnInit(): void {
    this.baseType = this.viewData.baseType;
    this.buildGridOptions();
  }

  buildGridOptions = () => {
    this.gridOptions = {
      autobind: true,
      pageable: {
        pageSizeSetting: this.localSettings.keys.caseView.attachmentsModal.pageNumber,
        pageSizes: [10, 20, 50, 100, 250]
      },
      navigable: true,
      sortable: true,
      reorderable: true,
      read$: (queryParams) => {
        return this.service.getAttachments$(this.viewData.baseType, this.viewData.key, queryParams);
      },
      columns: this.getColumns(),
      columnPicker: true,
      columnSelection: {
        localSetting: this.localSettings.keys.attachment.columnsSelection
      }
    };

    if (!!this.viewData.canMaintainAttachment.canAdd || !!this.viewData.canMaintainAttachment.canEdit || !!this.viewData.canMaintainAttachment.canDelete) {
      this.gridOptions.showContextMenu = !!this.viewData.canMaintainAttachment.canEdit || !!this.viewData.canMaintainAttachment.canDelete;

      if (!!this.viewData.canMaintainAttachment.canAdd) {
        this.gridOptions.enableGridAdd = true;
        this.gridOptions.canAdd = true;
        this.gridOptions.gridAddDelegate = this.onRowAdd;
      }
    }
  };
  getColumns = (): Array<GridColumnDefinition> => {
    const columns: Array<GridColumnDefinition> = [
      {
        title: '',
        field: 'isPriorArt',
        template: true,
        menu: false,
        includeInChooser: false
      },
      {
        title: 'caseview.attachments.attachmentName',
        field: 'rawAttachmentName',
        template: true,
        menu: false,
        includeInChooser: false
      }, {
        title: 'caseview.attachments.activityType',
        field: 'activityType',
        menu: true,
        hidden: true
      }, {
        title: 'caseview.attachments.activityCategory',
        field: 'activityCategory',
        menu: true,
        hidden: true
      }, {
        title: 'caseview.attachments.activityDate',
        field: 'activityDate',
        defaultColumnTemplate: DefaultColumnTemplateType.date,
        type: 'date',
        menu: true,
        hidden: true
      }, {
        title: 'caseview.attachments.attachmentType',
        field: 'attachmentType',
        includeInChooser: false
      }, {
        title: 'caseview.attachments.language',
        field: 'language',
        menu: true,
        hidden: true
      }, {
        title: 'caseview.attachments.pageCount',
        field: 'pageCount',
        menu: true,
        hidden: true
      }, {
        title: 'eventNo',
        field: 'eventNo',
        hidden: true,
        filter: true,
        defaultFilters: !!this.eventDetails && _.isNumber(this.eventDetails.eventKey) ? [this.eventDetails.eventKey] : null,
        includeInChooser: false
      }
    ];

    if (!this.viewData.isExternal && this.baseType === 'case') {
      columns.splice(5, 0, {
        title: 'caseview.attachments.eventDescription',
        field: 'eventDescription',
        includeInChooser: false
      }, {
        title: 'caseview.attachments.eventCycle',
        field: 'eventCycle',
        includeInChooser: false,
        filter: true,
        defaultFilters: !!this.eventDetails && _.isNumber(this.eventDetails.eventCycle) ? [this.eventDetails.eventCycle] : null
      }, {
        title: 'caseview.attachments.isPublic',
        field: 'isPublic',
        defaultColumnTemplate: DefaultColumnTemplateType.selection,
        menu: true,
        hidden: true,
        disabled: true
      });
    } else {
      columns.splice(9, 0, {
        title: 'caseview.attachments.eventCycle',
        field: 'eventCycle',
        includeInChooser: false,
        hidden: true,
        defaultFilters: !!this.eventDetails && _.isNumber(this.eventDetails.eventCycle) ? [this.eventDetails.eventCycle] : null
      });
    }

    if (this.baseType === 'priorArt') {
      columns.splice(0, 1);
    }

    return columns;
  };
  displayTaskItems = (dataItem: any): void => {
    this.taskItems = [];
    if (this.viewData.canMaintainAttachment.canEdit) {
      this.taskItems.push({
        id: 'edit',
        text: 'caseview.actions.events.editAttachment',
        icon: 'cpa-icon cpa-icon-pencil-square-o',
        action: this.onRowEdit
      });
    }
    if (this.viewData.canMaintainAttachment.canDelete) {
      this.taskItems.push({
        id: 'delete',
        text: 'caseview.actions.events.deleteAttachment',
        icon: 'cpa-icon cpa-icon-trash-o',
        action: this.deleteAttachment
      });
    }
  };

  onMenuItemSelected = (menuEventDataItem: any): void => {
    menuEventDataItem.event.item.action(menuEventDataItem.dataItem);
  };

  onRowAdd = () => {
    this.onRowAddedEdited(null, true);
  };

  onRowEdit = (dataItem: any) => {
    this.service.getAttachment$(this.baseType, this.viewData.key, dataItem.activityId, dataItem.sequenceNo).subscribe((data) => {
      this.onRowAddedEdited(data, false);
    });
  };

  deleteAttachment = (dataItem: any): void => {
    const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('attachmentsIntegration.deleteConfirmation');

    const closedWithoutConfirm = this.ipxNotificationService.onHide$.pipe(filter((n: HideEvent) => n.isCancelOrEscape), map(a => false));
    const confirmed = notificationRef.content.confirmed$.pipe(map(c => true));

    race(closedWithoutConfirm, confirmed)
      .pipe(take(1), takeUntil(this.destroy$))
      .subscribe((isConfirmed: boolean) => {
        if (isConfirmed) {
          this.service.deleteAttachment(this.baseType, this.viewData.key, dataItem, this.baseType === 'activity')
            .pipe(take(1), takeUntil(this.destroy$))
            .subscribe((res) => {
              this.notificationService.success('attachmentsIntegration.deleteSuccess');
              this.dataModified = true;
              this.dataModifiedChange.emit(this.dataModified);
              this.grid.search();
            });
        }
      });
  };

  private readonly onRowAddedEdited = (data: any, isAdding: boolean) => {
    let param = {};
    if (this.baseType === 'case') {
        param = this.eventDetails;
    } else if (this.baseType === 'priorArt') {
        param = {
            caseId: this._caseKey
        };
    }
    this.service.attachmentMaintenanceView$(this.baseType, this.viewData.key, param)
      .subscribe(result => {
        if (this.baseType === 'case' && _.isNumber(this.viewData.key) && this.eventDetails && this.eventDetails.eventCycle && !!result.event && !_.isNumber(result.event.eventCycle)) {
          result.event.cycle = this.eventDetails.eventCycle;
        }

        this.modalRef = this.modalService.openModal(AttachmentMaintenanceComponent, {
          animated: false,
          class: 'modal-xl',
          ignoreBackdropClick: true,
          initialState: {
            viewData: { ...result, ...{ id: this.viewData.key, baseType: this.baseType }, ...{ event: result.event } },
            activityAttachment: data,
            activityDetails: result.activityDetails || {}
          }
        });

        this.modalRef.content.onClose$.pipe(takeWhile(() => !!this.modalRef.content)).subscribe(value => {
          if (value) {
            this.grid.search();
            this.dataModified = true;
            this.dataModifiedChange.emit(this.dataModified);
          }
        });
      });
  };
  getUrl = (dataItem: any): void => {

    const allowedAttachmentTypes = ['http', 'iwl'];
    const filePath: string = dataItem.filePath;
    const openClientDirectly = _.any(allowedAttachmentTypes, (a) => {
      return filePath && filePath.toLowerCase().startsWith(a);
    });

    const url = openClientDirectly ? filePath :
      'api/attachment/file?activityKey=' + dataItem.activityId + '&sequenceKey=' + dataItem.sequenceNo + '&path=' + encodeURIComponent(dataItem.filePath);

    window.open(url);
  };

}
