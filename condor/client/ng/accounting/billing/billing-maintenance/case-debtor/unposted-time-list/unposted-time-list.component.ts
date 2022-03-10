import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';

@Component({
    selector: 'ipx-unposted-time-list',
    templateUrl: './unposted-time-list.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class UnpostedTimeListComponent implements OnInit {
    gridOptions: IpxGridOptions;
    @Input() unpostedCaseTimeList: any;
    @Input() caseIRN: string;
    @Input() total: number;

    constructor(readonly cdRef: ChangeDetectorRef, private readonly sbsModalRef: BsModalRef) { }

    // tslint:disable-next-line: cyclomatic-complexity
    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
        this.cdRef.detectChanges();
    }

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            sortable: true,
            reorderable: false,
            showGridMessagesUsingInlineAlert: false,
            read$: () => {
                return of(this.unpostedCaseTimeList).pipe(delay(300));
            },
            columns: this.getColumns()
        };
    }

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'accounting.billing.caseUnpostedTime.name',
            field: 'Name',
            sortable: false
        }, {
            title: 'accounting.billing.caseUnpostedTime.startTime',
            field: 'StartTime',
            template: true,
            sortable: false
        }, {
            title: 'accounting.billing.caseUnpostedTime.totalTime',
            field: 'TotalTime',
            template: true,
            sortable: false,
            headerClass: 'k-header-right-aligned'
        }, {
            title: 'accounting.billing.caseUnpostedTime.timeValue',
            field: 'TimeValue',
            sortable: false,
            template: true,
            headerClass: 'k-header-right-aligned'
        }];

        return columns;
    };

    cancel = (): void => {
        this.sbsModalRef.hide();
    };
}
