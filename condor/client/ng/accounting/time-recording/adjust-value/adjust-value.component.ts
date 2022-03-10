import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnInit, Output } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { debounceTime } from 'rxjs/operators';
import { TimeEntry } from '../time-recording-model';
import { AdjustValueService, TimeCost } from './adjust-value.service';

@Component({
    selector: 'adjust-value',
    templateUrl: './adjust-value.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    styleUrls: ['adjust-value.component.scss']
})
export class AdjustValueComponent implements OnInit, AfterViewInit {

    item: TimeEntry;
    viewItem: TimeCost;
    modalRef: BsModalRef;
    canSave: boolean;
    originalLocalValue?: number;
    originalForeignValue?: number;
    staffNameId?: number;
    @Output() readonly refreshGrid = new EventEmitter<number>();

    constructor(bsModalRef: BsModalRef, private readonly adjustValueService: AdjustValueService, private readonly cdRef: ChangeDetectorRef) {
        this.modalRef = bsModalRef;
    }

    ngOnInit(): void {
        this.viewItem = { ...this.viewItem, ...this.item };
        this.originalLocalValue = this.item.localValue;
        this.originalForeignValue = this.item.foreignValue;
    }

    ngAfterViewInit(): void {
        this.canSave = false;
    }

    localAmountChanged = (value: number): void => {
        if (value === null) {

            return;
        }
        const request: TimeCost = {
            wipCode: this.item.activityKey,
            caseKey: this.item.caseKey,
            nameKey: this.item.nameKey,
            currencyCode: this.item.foreignCurrency,
            exchangeRate: this.item.exchangeRate,
            localValueBeforeMargin: value,
            entryNo: this.item.entryNo,
            staffKey: this.staffNameId
        };

        this.adjustValueService.previewCost(request)
            .pipe(debounceTime(500))
            .subscribe((response: TimeCost) => {
                this.canSave = response.localValue !== this.originalLocalValue;
                this.viewItem.localValue = response.localValue;
                this.viewItem.localDiscount = response.localDiscount;
                this.viewItem.foreignValue = response.foreignValue;
                this.viewItem.foreignDiscount = response.foreignDiscount;
                this.viewItem.localMargin = response.localMargin;
                this.viewItem.foreignMargin = response.foreignMargin;
                this.viewItem.exchangeRate = response.exchangeRate;
                this.viewItem.marginNo = response.marginNo;
                this.viewItem.staffKey = response.staffKey;
                this.viewItem.wipCode = response.wipCode;
                this.viewItem.timeUnits = response.timeUnits;
                this.cdRef.detectChanges();
            });

    };

    foreignAmountChanged = (value: number): void => {
        if (value === null) {

            return;
        }
        const request: TimeCost = {
            wipCode: this.item.activityKey,
            caseKey: this.item.caseKey,
            nameKey: this.item.nameKey,
            currencyCode: this.item.foreignCurrency,
            exchangeRate: this.item.exchangeRate,
            foreignValueBeforeMargin: value,
            entryNo: this.item.entryNo,
            staffKey: this.staffNameId
        };

        this.adjustValueService.previewCost(request)
            .pipe(debounceTime(500))
            .subscribe((response: TimeCost) => {
                this.canSave = response.foreignValue !== this.originalForeignValue;
                this.viewItem.localValue = response.localValue;
                this.viewItem.localDiscount = response.localDiscount;
                this.viewItem.foreignValue = response.foreignValue;
                this.viewItem.foreignDiscount = response.foreignDiscount;
                this.viewItem.localMargin = response.localMargin;
                this.viewItem.foreignMargin = response.foreignMargin;
                this.viewItem.exchangeRate = response.exchangeRate;
                this.viewItem.marginNo = response.marginNo;
                this.viewItem.staffKey = response.staffKey;
                this.viewItem.wipCode = response.wipCode;
                this.viewItem.timeUnits = response.timeUnits;
                this.cdRef.detectChanges();
            });

    };

    saveValues(): void {
        if (!this.canSave) {
            return;
        }
        this.adjustValueService.saveAdjustedValues(this.viewItem as any).subscribe((response: any) => {
            this.refreshGrid.emit(response.entryNo);
            this.modalRef.hide();
        });
    }

    cancelDialog(): void {
        this.refreshGrid.emit(null);
        this.modalRef.hide();
    }
}