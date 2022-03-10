import { ChangeDetectionStrategy, Component, Input, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import * as _ from 'underscore';

@Component({
    selector: 'ipx-debtor-warnings',
    templateUrl: './debtor-warnings.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DebtorWarningsComponent implements OnInit {

    warnings: Array<any> = [];
    gridOptions: IpxGridOptions;
    warningsCount = 0;
    @Input() debtorWarnings: Array<any>;
    @Input() hasDiscounts: boolean;
    @Input() showMultiCase: boolean;
    @ViewChild('detailsTemplate', { static: true }) detailsTemplate: TemplateRef<any>;
    @ViewChild('debtorWarningsGrid', { static: false }) grid: IpxKendoGridComponent;
    ngOnInit(): void {
        this.warningsCount = (this.debtorWarnings.length > 0 ? 1 : 0) + (this.hasDiscounts ? 1 : 0) + (this.showMultiCase ? 1 : 0);
        if (this.warningsCount > 0) {
            this.warnings.push({ detail: 'accounting.billing.step1.debtors.warnings' });
        }
        this.gridOptions = this.buildGridOptions();
    }

    private buildGridOptions(): IpxGridOptions {
        const options: IpxGridOptions = {
            groups: [],
            hideHeader: true,
            selectable: {
                mode: 'single'
            },
            hideExtraBreakInGrid: true,
            read$: () => of(this.warnings).pipe(delay(200)),
            onDataBound: (data: any) => {
                if (this.grid) {
                    this.grid.wrapper.expandRow(0);
                }
            },
            columns: [{
                field: 'detail', title: '', template: true
            }]
        };

        options.detailTemplateShowCondition = (dataItem: any): boolean => true;
        options.detailTemplate = this.detailsTemplate;

        return options;
    }

    trackByFn = (index, item): any => {
        return index;
    };
}