import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { DmsService } from 'common/case-name/dms/dms.service';
import { ConnectionResponseModel, DmsIntegrationService } from 'configuration/dms-integration/dms-integration.service';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { IManageCredentialsInputComponent } from './i-manage-database/i-manage-credentials-input/i-manage-credentials-input.component';
import { IManageDatabaseModelComponent } from './i-manage-database/i-manage-database-model.component';

@Component({
  selector: 'i-manage-database',
  templateUrl: './i-manage-database.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IManageDatabaseComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
  @Input() topic: Topic;
  gridOptions: IpxGridOptions;
  databases: Array<any>;
  testingConnection = false;
  maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
  constructor(private readonly modalService: IpxModalService,
    private readonly cdRef: ChangeDetectorRef,
    private readonly dmsService: DmsIntegrationService,
    private readonly translate: TranslateService,
    private readonly notificationService: NotificationService,
    readonly service: DmsService) { }

  ngOnDestroy(): void {
    this.service.disconnectBindings();
  }

  ngOnInit(): void {
    this.topic.setErrors(false);
    this.topic.hasChanges = false;
    this.topic.getDataChanges = this.getChanges;
    this.topic.handleErrors = this.applyErrorResponses;
    this.databases = this.topic.params.viewData && this.topic.params.viewData.imanageSettings ? this.topic.params.viewData.imanageSettings.databases : [];
    this.gridOptions = this.buildGridOptions();
  }

  ngAfterViewInit(): void {
    this.cdRef.detectChanges();
  }

  onRowAddedOrEdited = (data: any, isAdding: boolean): void => {
    const modal = this.modalService.openModal(IManageDatabaseModelComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-xl',
      initialState: {
        isAdding,
        grid: this.grid,
        dataItem: data.dataItem,
        rowIndex: data.rowIndex,
        topic: this.topic
      }
    });
    modal.content.onClose$.subscribe(
      (event) => {
        if (event.success) {
          const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: event.formGroup } as any;
          this.gridOptions.maintainFormGroup$.next(rowObject);
          this.updateChangeStatus();
        }
      }
    );
  };

  getCredentials = (databases: Array<any>): Observable<any> => {
    const showCredentials = this.dmsService.getRequiresCredentials(databases);
    if (!showCredentials.showUsername && !showCredentials.showPassword) {
      return of({});
    }

    const modal = this.modalService.openModal(IManageCredentialsInputComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState: {
        databases
      }
    });

    return modal.content.onClose$;
  };

  testConnections = (): void => {
    const databases = this.getChanges().Databases as Array<any>;
    this.testingConnection = true;
    this.getCredentials(databases).subscribe((credentials) => {
      if (credentials) {
        this.dmsService.testConnections$(credentials.username, credentials.password, databases).then(response => {
          this.applyErrorResponses(response);
          this.testingConnection = false;
          this.grid.checkChanges();
        });
      } else {
        this.testingConnection = false;
        this.grid.checkChanges();
      }
    });
  };

  applyErrorResponses = (response: Array<ConnectionResponseModel>): void => {
    const newDatabases = this.databases.filter(_ => _.status !== 'D');
    let anyErrors = false;
    response.forEach((element, index) => {
      newDatabases[index].hasErrors = !element.success;
      if (!element.success) {
        anyErrors = true;
      }
      newDatabases[index].errorMessages = element.errorMessages;
      if (this.grid.rowEditFormGroups && this.grid.rowEditFormGroups[newDatabases[index].siteDbId]) {
        this.grid.rowEditFormGroups[newDatabases[index].siteDbId].value.hasErrors = !element.success;
        this.grid.rowEditFormGroups[newDatabases[index].siteDbId].value.errorMessages = element.errorMessages;
      }
    });
    if (anyErrors) {
      this.notificationService.alert({
        message: this.translate.instant('dmsIntegration.iManage.unsuccessfulConnection')
      });
    } else {
      this.notificationService.success(this.translate.instant('dmsIntegration.iManage.successfulConnection'));
    }
    this.grid.checkChanges();
    this.cdRef.detectChanges();
  };

  updateChangeStatus = (): void => {
    this.grid.checkChanges();
    this.cdRef.detectChanges();
    const dataRows = Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
    this.topic.setCount.emit(dataRows.length);
    this.topic.hasChanges = dataRows.some((r) => r.status);
    this.dmsService.raisePendingChanges(this.topic.hasChanges);
    this.dmsService.raiseHasErrors(this.topic.getErrors());
  };

  getChanges = (): { [key: string]: any; } => {
    const data = {
      ['Databases']: []
    };
    const dataRows = Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
    this.dmsService.hasPendingDatabaseChanges$.next(false);
    dataRows.forEach((r) => {
      if (!r.status) {
        data.Databases.push(r);
      } else if ((r.status === rowStatus.Adding || r.status === rowStatus.editing) && this.grid.rowEditFormGroups && this.grid.rowEditFormGroups[r.siteDbId]) {
        const value = this.grid.rowEditFormGroups[r.siteDbId].value;
        data.Databases.push(value);
        this.dmsService.hasPendingDatabaseChanges$.next(true);
      }
    });

    return data;
  };

  private readonly buildGridOptions = (): IpxGridOptions => {
    const options: IpxGridOptions = {
      sortable: false,
      showGridMessagesUsingInlineAlert: false,
      autobind: true,
      reorderable: false,
      pageable: false,
      enableGridAdd: true,
      selectable: {
        mode: 'single'
      },
      gridMessages: {
        noResultsFound: 'grid.messages.noItems',
        performSearch: ''
      },
      read$: () => {
        return of(this.databases).pipe(delay(100));
      },
      onDataBound: (data: any) => {
        const total = data.total ? data.total : data.length;
        if (data && total && this.topic.setCount) {
          this.topic.setCount.emit(total);
        }
      },
      columns: this.getColumns(),
      canAdd: true,
      rowMaintenance: {
        canEdit: true,
        canDelete: true,
        rowEditKeyField: 'siteDbId'
      },
      maintainFormGroup$: this.maintainFormGroup$
    };

    return options;
  };

  getManifest = (dataItem: any) => {
    this.dmsService.getManifest(dataItem);
  };

  private readonly getColumns = (): Array<GridColumnDefinition> => {
    return [{
      title: 'dmsIntegration.iManage.server',
      field: 'server',
      sortable: false,
      template: true
    }, {
      title: 'dmsIntegration.iManage.database',
      field: 'database',
      sortable: false
    }, {
      title: 'dmsIntegration.iManage.integrationType',
      field: 'integrationType',
      sortable: false
    }, {
      title: 'dmsIntegration.iManage.customerId',
      field: 'customerId',
      sortable: false
    }, {
      title: 'dmsIntegration.iManage.loginType',
      field: 'loginType',
      sortable: false
    }, {
      title: 'dmsIntegration.iManage.status',
      field: 'hasErrors',
      template: true,
      width: 20,
      sortable: false
    }, {
      title: 'dmsIntegration.iManage.manifest',
      field: 'manifest',
      sortable: false,
      template: true,
      headerTooltip: 'dmsIntegration.iManage.manifestTooltip'
    }
    ];
  };
}
