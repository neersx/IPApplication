import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { RuleOverView } from '../maintenance-model';
import { SanityCheckMaintenanceService } from '../sanity-check-maintenance.service';

@Component({
    selector: 'ipx-sanity-check-rule-overview',
    templateUrl: './rule-overview.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class SanityCheckRuleOverviewComponent implements TopicContract, OnInit {
    topic: Topic;
    view?: any;
    formData?: any;
    isDeferredCheked = new BehaviorSubject(false);
    @ViewChild('frm', { static: true }) form: NgForm;

    constructor(private readonly service: SanityCheckMaintenanceService, private readonly cdr: ChangeDetectorRef, private readonly destroy$: IpxDestroy) {
    }

    ngOnInit(): void {
        this.view = (this.topic.params?.viewData as RuleOverView);
        this.formData = !!this.view ? { ...this.view } : { inUse: true };
        this.isRuleDescriptionEntered = !!this.formData.ruleDescription;
        this.setInformationFlag();

        this.topic.getDataChanges = this.getDataChanges;
        this.form.statusChanges
            .pipe(takeUntil(this.destroy$))
            .subscribe(() => {
                const hasErrors = Object.values(this.form.controls)
                    .map((c) => { return { errors: c.errors, touched: c.touched }; })
                    .filter((c) => c.touched && c.errors).length > 0;

                this.topic.hasChanges = this.form.dirty;
                this.topic.setErrors(hasErrors);
                this.service.raiseStatus(this.topic.key, this.topic.hasChanges, hasErrors, this.form.valid);
            });
    }

    getDataChanges = (): any => {
        if (this.form.invalid) {
            throw new Error('form not valid');
        }
        const r = {};
        r[this.topic.key] = {
            ...this.formData,
            ...{
                sanityCheckSql: this.formData.sanityCheckSql?.key,
                mayBypassError: this.formData.mayBypassError?.key,
                informationOnly: this.getInformationFlag()
            }
        };

        return r;
    };

    getInformationFlag = (): boolean => {
        if (this.formData.informationOnlyFlag === 'errorWithBypass' || this.formData.informationOnlyFlag === 'error') {
            return false;
        }

        return true;
    };

    setInformationFlag = (): void => {
        this.formData.informationOnlyFlag = !!this.formData.informationOnly
            ? 'info'
            : (!!this.formData.mayBypassError ? 'errorWithBypass' : 'error');
    };

    isRuleDescriptionEntered = false;
    displayMessageChanged = (data: any): any => {
        if (!this.isRuleDescriptionEntered && data?.type === 'change') {
            this.formData.ruleDescription = this.formData.displayMessage;
        }
    };

    ruleDescriptionChanged = (data: any): any => {
        if (data?.type === 'change') {
            this.isRuleDescriptionEntered = !!this.formData.ruleDescription ? true : false;
        }
    };

    severityChanged = (): void => {
        if (this.formData.informationOnlyFlag !== 'errorWithBypass') {
            this.formData.mayBypassError = null;
        }

        this.cdr.markForCheck();
    };
}