import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { of, Subject } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
@Component({
    selector: 'ipx-case-status-restriction',
    templateUrl: './case-status-restriction.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseStatusRestrictionComponent implements OnInit {
    @Input() caseList: any;
    @Input() allcasesRestricted: any;
    gridOptions: IpxGridOptions;
    private readonly modalRef: BsModalRef;
    onClose$ = new Subject();

    constructor(private readonly cdRef: ChangeDetectorRef, bsModalRef: BsModalRef) {
        this.modalRef = bsModalRef;
    }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
        this.cdRef.markForCheck();
    }

    proceed = () => {
        this.modalRef.hide();
        this.onClose$.next(true);
    };

    cancel = () => {
        this.modalRef.hide();
        this.onClose$.next(false);
    };

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: false,
            sortable: false,
            reorderable: false,
            read$: () => {
                return of(this.caseList).pipe(delay(100));
            },
            columns: this.getColumns()
        };
    }

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'accounting.billing.step1.columns.irn',
            field: 'CaseReference',
            template: true,
            sortable: false
        }, {
            title: 'accounting.billing.step1.columns.officialNo',
            field: 'OfficialNumber',
            sortable: false
        }, {
            title: 'accounting.billing.step1.columns.title',
            field: 'Title',
            sortable: false
        }, {
            title: 'accounting.billing.step1.columns.status',
            field: 'CaseStatus',
            sortable: false
        }];

        return columns;
    };
}