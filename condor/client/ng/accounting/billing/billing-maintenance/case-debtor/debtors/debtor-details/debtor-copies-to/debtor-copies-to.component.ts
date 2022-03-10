import { AfterViewInit, ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { BillingService } from 'accounting/billing/billing-service';
import { BehaviorSubject, of, Subscription } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import * as _ from 'underscore';

@Component({
    selector: 'ipx-debtor-copies-to',
    templateUrl: './debtor-copies-to.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DebtorCopiesToComponent implements OnInit, AfterViewInit, OnDestroy {

    copiesToLabel: Array<any> = [];
    gridOptions: IpxGridOptions;
    @Input() copiesTo: Array<any>;
    @Input() debtorNameId: number;
    @Input() isFinalised: boolean;
    @ViewChild('detailsTemplate', { static: true }) detailsTemplate: TemplateRef<any>;
    copiesToCount: BehaviorSubject<number> = new BehaviorSubject<any>(0);
    copiesToCount$ = this.copiesToCount.asObservable();
    copiesToCountSubscription: Subscription;

    constructor(private readonly billingService: BillingService) { }

    ngOnInit(): void {
        this.copiesToLabel.push({ detail: 'accounting.billing.step1.debtors.copiesToNames' });
        this.copiesToCount.next(this.copiesTo.length);
        this.gridOptions = this.buildGridOptions();
    }

    ngAfterViewInit(): void {
        this.copiesToCountSubscription = this.billingService.copiesToCount$
            .subscribe((e) => {
                if (e != null && e.debtorNameId === this.debtorNameId) {
                    this.copiesToCount.next(e.count);
                }
            });
    }

    ngOnDestroy(): void {
        if (this.copiesToCountSubscription) {
            this.copiesToCountSubscription.unsubscribe();
        }
    }

    private buildGridOptions(): IpxGridOptions {
        const options: IpxGridOptions = {
            groups: [],
            hideHeader: true,
            selectable: {
                mode: 'single'
            },
            hideExtraBreakInGrid: true,
            read$: () => of(this.copiesToLabel).pipe(delay(100)),
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