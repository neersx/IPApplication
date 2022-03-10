import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, NgForm } from '@angular/forms';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { TaxCodeService } from '../tax-code.service';

@Component({
    selector: 'ipx-tax-code-overview',
    templateUrl: './tax-code-overview.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class TaxCodeOverviewComponent implements OnInit {
    topic: Topic;
    formData: any = {};
    viewData: any;
    @ViewChild('overViewForm', { static: true }) overViewForm: NgForm;
    constructor(public cdRef: ChangeDetectorRef, private readonly taxCodeService: TaxCodeService) { }

    ngOnInit(): void {
        if (this.topic.params?.viewData) {
            this.viewData = { ...this.topic.params.viewData };
        }
        this.initTopicsData();
        Object.assign(this.topic, {
            getFormData: this.getFormData,
            isDirty: this.isDirty,
            isValid: this.isValid,
            setPristine: this.setPristine,
            clear: this.clear,
            revert: this.revert
        });
    }
    clear = (): void => {
        this.initTopicsData();
    };

    getFormData = (): any => {
        if (this.isValid()) {
            return { formData: { overviewDetails: this.formData } };
        }
    };

    isValid = (): boolean => {
        return this.overViewForm.valid;
    };

    isDirty = (): boolean => {
        return this.overViewForm.dirty;
    };

    setPristine = (): void => {
        _.each(this.overViewForm.controls, (c: AbstractControl) => {
            c.markAsPristine();
            c.markAsUntouched();
        });
    };

    revert = (): any => {
        this.setPristine();
        this.formData = {};
    };

    initTopicsData = () => {
        this.taxCodeService.overviewDetails(this.viewData.taxRateId).subscribe(result => {
            this.formData = result;
            this.taxCodeService._taxCodeDescription$.next(this.formData.description);
            this.cdRef.markForCheck();
        });
    };
}