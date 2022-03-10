import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { SplitWipData } from './split-wip.model';

@Component({
    selector: 'ipx-split-wip-header',
    templateUrl: './split-wip-header.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class SplitWipHeaderComponent implements OnInit {
    @Input() splitWipData: SplitWipData;
    @Input() reasonCollection: any;
    reason: any;
    isForeignCurrency = false;
    unallocatedAmount$: Observable<number>;
    unallocatedAmount: BehaviorSubject<number> = new BehaviorSubject<number>(null);
    @ViewChild('reasonForm', { static: false }) reasonForm: any;

    constructor(private readonly translate: TranslateService) {
        this.unallocatedAmount$ = this.unallocatedAmount.asObservable();
    }
    ngOnInit(): void {
        this.isForeignCurrency = this.splitWipData && this.splitWipData.foreignCurrency ? true : false;
    }

    setReasonDirty = () => {
        this.reasonForm.control.controls.reason.markAsDirty();
        this.reasonForm.control.controls.reason.markAsTouched();
    };

    getWipCategoryLabel = (code): string => {
        let label = this.translate.instant('wip.splitWip.activity');
        if (code === WipCategoryCode.Disbursement) {
            label = this.translate.instant('wip.splitWip.disbursement');
        }
        if (code === WipCategoryCode.Expense) {
            label = this.translate.instant('wip.splitWip.expense');
        }

        return label;
    };
}

export enum WipCategoryCode {
    Disbursement = 'PD',
    Expense = 'OR'
}