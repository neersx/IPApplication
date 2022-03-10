import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { BillingService } from 'accounting/billing/billing-service';
import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { BehaviorSubject, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import * as _ from 'underscore';
import { MaintainDebtorCopiesToComponent } from './maintain-debtor-copies-to.component';

@Component({
    selector: 'ipx-debtor-copies-to-names',
    templateUrl: './debtor-copies-to-grid.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class DebtorCopiesToNamesGridComponent implements OnInit {
    @Input() copiesTo: Array<any>;
    @Input() isFinalised: boolean;
    @Input() debtorNameId: number;
    maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
    @ViewChild('copiesToGrid', { static: true }) grid: IpxKendoGridComponent;
    @Output() readonly countChange: EventEmitter<any> = new EventEmitter<any>();

    gridOptions: IpxGridOptions;
    formGroup: FormGroup;
    currentRowIndex: number;
    copiesToCount: number;
    reasonList: any;

    constructor(private readonly modalService: IpxModalService,
        private readonly billingStepsService: BillingStepsPersistanceService,
        private readonly cdref: ChangeDetectorRef,
        private readonly billingService: BillingService) {
        this.reasonList = this.billingService.reasonList$.getValue();
    }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
        this.setAddressChangeReason();
    }

    setAddressChangeReason = (): void => {
        if (this.reasonList && this.reasonList.length > 0) {
            _.each(this.copiesTo, (row: any) => {
                if (row.AddressChangeReasonId) {
                    row.AddressChangeReason = _.first(_.filter(this.reasonList, (r: any) => {
                        return r.Id === row.AddressChangeReasonId;
                    })).Name;
                }
            });
        }
    };

    private buildGridOptions(): IpxGridOptions {
        const options: IpxGridOptions = {
            sortable: false,
            showGridMessagesUsingInlineAlert: false,
            navigable: true,
            pageable: false,
            selectable: {
                mode: 'single'
            },
            canAdd: !this.isFinalised,
            enableGridAdd: !this.isFinalised,
            read$: () => {
                return of(this.copiesTo).pipe(delay(100));
            },
            maintainFormGroup$: this.maintainFormGroup$,
            rowMaintenance: {
                canEdit: !this.isFinalised,
                canDelete: !this.isFinalised,
                rowEditKeyField: 'CopyToNameId'
            },
            columns: this.getColumns()
        };

        return options;
    }

    onRowAddedOrEdited = (data: any): void => {
        const modal = this.modalService.openModal(MaintainDebtorCopiesToComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                isAdding: data.dataItem.status === rowStatus.Adding,
                grid: this.grid,
                dataItem: data.dataItem,
                debtorNameId: this.debtorNameId,
                rowIndex: data.rowIndex,
                reasonList: this.reasonList
            }
        });
        modal.content.onClose$.subscribe(
            (event: any) => {
                this.onCloseModal(event, data);
            }
        );
    };

    onCloseModal(event, data): any {
        if (event.success) {
            const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: event.formGroup } as any;
            this.gridOptions.maintainFormGroup$.next(rowObject);
            this.setAddressChangeReason();
            this.grid.checkChanges();
            this.updatePersistanceService();
        } else {
            this.removeAddedEmptyRow(data.dataItem.status);
        }
    }

    removeAddedEmptyRow = (status: string): any => {
        const rows: any = this.grid.wrapper.data;
        const emptyRowIndex = rows.findIndex(x => x === undefined);
        if (emptyRowIndex > -1 && status === rowStatus.Adding) {
            this.grid.removeRow(emptyRowIndex);
            this.cdref.markForCheck();

            return;
        }
    };

    onRowDeleted = ($event: any): void => {
        this.updatePersistanceService();
    };

    cancelRowEdit = ($event: any): void => {
        this.updatePersistanceService();
    };

    updatePersistanceService = (): void => {
        const rows: any = this.grid.wrapper.data;
        const rowsToBeAdded = _.filter(rows, (row: any) => {
            return row.status !== rowStatus.deleting;
        });
        const data = this.billingStepsService.getStepData(1);
        if (data && data.stepData && data.stepData.debtorData) {
            const debtorRow = _.first(_.filter(data.stepData.debtorData, (row: any) => {
                return row.NameId === this.debtorNameId;
            }));
            if (debtorRow) {
                debtorRow.copiesTo = rowsToBeAdded;
            }
        }
        this.billingService.copiesToCount$.next({
            debtorNameId: this.debtorNameId,
            count: rowsToBeAdded.length
        });
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            field: 'CopyToName',
            title: 'accounting.billing.step1.debtors.copiesTo.columns.copyTo',
            width: 300,
            sortable: false,
            template: true
        }, {
            field: 'ContactName',
            title: 'accounting.billing.step1.debtors.copiesTo.columns.contactName',
            width: 200,
            sortable: false,
            template: true
        }, {
            field: 'Address',
            title: 'accounting.billing.step1.debtors.copiesTo.columns.address',
            width: 300,
            sortable: false,
            template: true
        }, {
            field: 'AddressChangeReason',
            title: 'accounting.billing.step1.debtors.copiesTo.columns.reason',
            width: 300,
            sortable: false,
            template: true
        }];

        return columns;
    };
}