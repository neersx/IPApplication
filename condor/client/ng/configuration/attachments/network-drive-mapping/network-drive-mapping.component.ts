import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormGroup, NgForm } from '@angular/forms';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import { AttachmentConfigurationService } from '../attachments-configuration.service';
import { NetworkDriveMappingMaintenanceComponent } from './network-drive-mapping-maintenance.component';

@Component({
    selector: 'ipx-attachments-network-drive-mapping',
    templateUrl: './network-drive-mapping.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class NetworkDriveMappingComponent implements TopicContract, OnInit {
    @ViewChild('ipxKendoGridRef') grid: IpxKendoGridComponent;
    @Input() topic: Topic;
    viewData?: TopicViewData;
    formData?: any;
    form?: NgForm;
    gridOptions: IpxGridOptions;
    networkDriveMapping: Array<any>;
    maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);

    constructor(private readonly modalService: IpxModalService, private readonly cdRef: ChangeDetectorRef,
        private readonly service: AttachmentConfigurationService) {

    }

    ngOnInit(): void {
        this.topic.getDataChanges = this.getChanges;
        this.networkDriveMapping = this.topic.params && this.topic.params.viewData ? this.topic.params.viewData : [];
        this.gridOptions = this.buildGridOptions();
    }

    onRowAddedEdited = (data: any, isAdding: boolean) => {
        const modal = this.showMaintenanceModal(data, isAdding);
        modal.subscribe((applied) => {
            if (applied.success) {
                const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: applied.formGroup } as any;
                this.gridOptions.maintainFormGroup$.next(rowObject);
                this.updateChangeStatus();
            }
        });
    };

    updateChangeStatus = (): void => {
        this.grid.checkChanges();
        this.cdRef.detectChanges();
        const dataRows = this.grid.getCurrentData();
        // this.topic.setCount.emit(dataRows.length);
        this.topic.hasChanges = dataRows.some((r) => r.status);
        this.service.raisePendingChanges(this.topic.hasChanges);
        this.service.raiseHasErrors(this.topic.getErrors());
    };

    private readonly showMaintenanceModal = (data: any, isAdding: boolean): Observable<any> => {
        const modal = this.modalService.openModal(NetworkDriveMappingMaintenanceComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                dataItem: data.dataItem,
                isAdding,
                grid: this.grid,
                rowIndex: data.rowIndex
            }
        });

        return modal.content.onClose$;
    };

    private readonly buildGridOptions = (): IpxGridOptions => {
        const options: IpxGridOptions = {
            sortable: false,
            showGridMessagesUsingInlineAlert: false,
            reorderable: false,
            pageable: false,
            gridMessages: {
                noResultsFound: 'grid.messages.noItems',
                performSearch: ''
            },
            read$: () => {
                return of(this.networkDriveMapping).pipe(delay(100));
            },
            columns: this.getColumns(),
            canAdd: true,
            enableGridAdd: true,
            rowMaintenance: {
                canEdit: true,
                canDelete: true,
                rowEditKeyField: 'networkDriveMappingId'
            },
            maintainFormGroup$: this.maintainFormGroup$
        };

        return options;
    };

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        return [{
            title: 'attachmentsIntegration.networkDriveMapping.driveLetter',
            field: 'driveLetter',
            sortable: false
        }, {
            title: 'attachmentsIntegration.networkDriveMapping.uncPath',
            field: 'uncPath',
            sortable: false
        }];
    };

    private readonly getChanges = (): { [key: string]: any } => {
        // return { storageLocations: this.grid.getCurrentData() };
        return this.tempMixDataAndFormsRecord();
    };

    private readonly tempMixDataAndFormsRecord = () => {
        const data = {
            ['networkDrives']: []
        };
        const dataRows = this.grid.getCurrentData();
        dataRows.forEach((r) => {
            if (!r.status) {
                data.networkDrives.push(r);
            } else if ((r.status === rowStatus.Adding || r.status === rowStatus.editing) && this.grid.rowEditFormGroups && this.grid.rowEditFormGroups[r.networkDriveMappingId]) {
                const value = this.grid.rowEditFormGroups[r.networkDriveMappingId].value;
                data.networkDrives.push(value);
            }
        });

        return data;
    };
}

export class NetworkDriveMappingTopic extends Topic {
    key = 'networkDriveMapping';
    title = 'attachmentsIntegration.networkDriveMapping.title';
    readonly component = NetworkDriveMappingComponent;
    info = 'attachmentsIntegration.networkDriveMapping.info';
    constructor(public params: TopicParam) {
        super();
    }
}