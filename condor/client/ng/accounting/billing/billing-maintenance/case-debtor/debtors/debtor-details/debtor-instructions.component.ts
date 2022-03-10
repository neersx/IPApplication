import { ChangeDetectionStrategy, Component, Input, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import * as _ from 'underscore';

@Component({
    selector: 'ipx-debtor-instructions',
    templateUrl: './debtor-instructions.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DebtorInstructionsComponent implements OnInit {

    instructionsLabel: Array<any> = [];
    gridOptions: IpxGridOptions;
    @Input() instructions: string;
    @ViewChild('detailsTemplate', { static: true }) detailsTemplate: TemplateRef<any>;
    ngOnInit(): void {
        if (this.instructions && this.instructions.length > 0) {
            this.instructionsLabel.push({ detail: 'accounting.billing.step1.debtors.instructions' });
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
            read$: () => of(this.instructionsLabel).pipe(delay(100)),
            columns: [{
                field: 'detail', title: '', template: true
            }]
        };

        options.detailTemplateShowCondition = (dataItem: any): boolean => true;
        options.detailTemplate = this.detailsTemplate;

        return options;
    }
}