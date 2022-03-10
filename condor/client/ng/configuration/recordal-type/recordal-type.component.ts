import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BehaviorSubject, Subscription } from 'rxjs';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { MaintainRecordalTypeComponent } from './maintain-recordal-type/maintain-recordal-type.component';
import { RecordalTypePermissions } from './recordal-type.model';
import { RecordalTypeService } from './recordal-type.service';

@Component({
    selector: 'recordal-type',
    templateUrl: './recordal-type.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [
        slideInOutVisible
    ]
})

export class RecordalTypeComponent implements OnInit, OnDestroy {
    @Input() viewData: RecordalTypePermissions;
    gridOptions: IpxGridOptions;
    showSearchBar = true;
    searchText: string;
    deleteSubscription: Subscription;
    addedRecordId: number;
    maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
    @ViewChild('ipxKendoGridRef', { static: false }) grid: any;

    constructor(private readonly service: RecordalTypeService,
        private readonly modalService: IpxModalService,
        private readonly notificationService: NotificationService) {
    }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
    }

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
            read$: (queryParams) => {

                return this.service.getRecordalType({ text: this.searchText }, queryParams);
            },
            rowMaintenance: {
                canDelete: this.viewData.canDelete,
                canEdit: this.viewData.canEdit
            },
            customRowClass: (context) => {
                let returnValue = '';
                if (context.dataItem && context.dataItem.id === this.addedRecordId) {
                    returnValue += ' saved k-state-selected selected';
                }

                return returnValue;
            },
            enableGridAdd: this.viewData.canAdd,
            columns: this.getColumns()
        };
    }

    search(): void {
        this.gridOptions._search();
    }

    onRowAddedOrEdited(data: any, state: string): void {
        const modal = this.modalService.openModal(MaintainRecordalTypeComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                state,
                dataItem: !data ? { id: 0, status: rowStatus.Adding } : (data.dataItem ? data.dataItem : data),
                isAdding: state === rowStatus.Adding,
                existingTypes: this.grid.wrapper.data,
                viewData: this.viewData
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

    clear(): void {
        this.searchText = '';
        this.gridOptions._search();
    }

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'recordalType.column.recordalType',
            field: 'recordalType',
            sortable: true,
            template: true
        }, {
            title: 'recordalType.column.requestEvent',
            field: 'requestEvent',
            sortable: true
        }, {
            title: 'recordalType.column.requestAction',
            field: 'requestAction',
            sortable: true
        }, {
            title: 'recordalType.column.recordalEvent',
            field: 'recordalEvent',
            sortable: true
        }, {
            title: 'recordalType.column.recordalAction',
            field: 'recordalAction',
            sortable: true
        }];

        return columns;
    };

    onRowDeleted(data: any): void {
        this.notificationService.confirmDelete({
            message: 'picklistmodal.confirm.delete'
        }).then(() => {
            if (data) {
                this.deleteRecordalType(data.id);
            }
        });
    }

    deleteRecordalType(id: number): void {
        this.deleteSubscription = this.service.deleteRecordalType(id).subscribe((response: any) => {
            if (response) {
                if (response.result === 'success') {
                    this.notificationService.success('recordalType.deleteSuccess');
                    this.gridOptions._search();
                } else if (response.result === 'inUse') {
                    this.notificationService.alert({ message: 'recordalType.inUse', continue: 'Ok' });
                }
            }
        });
    }
}