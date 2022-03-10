import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { NameViewTopicBaseComponent } from '../name-view-topics.base.component';
import { NameViewService } from '../name-view.service';
@Component({
    selector: 'ipx-name-view-supplier-details',
    templateUrl: './supplier-details.html',
    styleUrls: ['./supplier-details.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class SupplierDetailsComponent extends NameViewTopicBaseComponent implements TopicContract, OnInit {
    topic: Topic;
    nameId: number;
    isMaintainable: boolean;
    supplierTypes: any = {};
    paymentTerms: any = {};
    taxRates: any = {};
    taxTreatments: any = {};
    paymentMethods: any = {};
    intoBankAccounts: any = {};
    paymentRestrictions: any = {};
    reasonsForRestrictions: any = {};
    formData: any = {};
    wipTemplateExtendQuery: any;
    sendToNameExtendQuery: any;
    sendToNameAttentionExtendQuery: any;
    warningMessage: string;
    isSaveEnabled: boolean;
    isHosted: boolean;
    @ViewChild('nameSupplierDetailsForm', { static: true }) ngForm: NgForm;
    originalFormData: any;

    constructor(private readonly service: NameViewService, private readonly cdr: ChangeDetectorRef, private readonly notificationService: NotificationService, private readonly windowParentMessagingService: WindowParentMessagingService) {
        super(cdr);
        this.wipTemplateExtendQuery = this.wipTemplatesFor.bind(this);
        this.sendToNameExtendQuery = this.sendToName.bind(this);
        this.sendToNameAttentionExtendQuery = this.sendToNameAttention.bind(this);
    }

    ngOnInit(): void {
        this.onInit();
        this.isHosted = this.topic.params.viewData.isHosted;

        this.ngForm.form.statusChanges.subscribe(() => {
            if (this.ngForm.form.dirty) {
                this.checkValidationAndEnableSave();
            }
        });
        this.ngForm.form.valueChanges.subscribe(() => {
            if (this.isHosted && this.ngForm.form.dirty) {
                this.windowParentMessagingService.postLifeCycleMessage({
                    action: 'onChange',
                    target: 'supplierHost',
                    payload: {
                        isDirty: this.ngForm.form.dirty
                    }
                });
            }
        });
        this.service.savedSuccessful.subscribe((isSaved: boolean) => {
            if (isSaved) {
                this.service.enableSave.next(false);
                this.markFormPristine(this.ngForm);
                // Update oldSendToName
                this.formData.oldSendToName = this.formData.sendToName;
                this.formData.oldSendToAddress = this.formData.sendToAddress;
                this.formData.oldSendToAttentionName = this.formData.sendToAttentionName;
                this.formData.oldRestrictionKey = this.formData.restrictionKey;
                this.formData.updateOutstandingPurchases = false;
            }
        });
        this.service.enableSave.subscribe((enableSave: boolean) => {
            this.isSaveEnabled = enableSave;
            this.cdr.detectChanges();
        });
        this.service.resetChanges.subscribe((val: boolean) => {
            if (val) {
                this.revert();
            }
        });
    }

    markFormPristine(form: NgForm): void {
        form.form.markAsPristine();
        Object.keys(form.form.controls).forEach(control => {
            form.controls[control].setErrors(null);
            this.cdr.detectChanges();
        });
    }

    initTopicsData = () => {
        this.isMaintainable = this.viewData.canMaintainName;
        this.supplierTypes = this.viewData.supplierTypes;
        this.taxRates = this.viewData.taxRates;
        this.paymentTerms = this.viewData.paymentTerms;
        this.taxTreatments = this.viewData.taxTreatments;
        this.nameId = this.viewData.nameId;
        this.paymentMethods = this.viewData.paymentMethods;
        this.intoBankAccounts = this.viewData.intoBankAccounts;
        this.paymentRestrictions = this.viewData.paymentRestrictions;
        this.reasonsForRestrictions = this.viewData.reasonsForRestrictions;
        this.service.getSupplierDetails$(this.viewData.nameId)
            .subscribe(details => {
                this.formData = details;
                this.defaultSendTo();
                this.originalFormData = {...this.formData};
                this.setReason();
                Object.assign(this.topic, { formData: this.formData });
                this.cdr.markForCheck();
            });
    };

    wipTemplatesFor(query: any): void {
        const extended = _.extend({}, query, {
            isTimesheetActivity: false
        });

        return extended;
    }

    sendToName(query: any): void {
        const extended = _.extend({}, query, {
            associatedNameId: this.formData.sendToName.key
        });

        return extended;
    }

    sendToNameAttention(query: any): void {
        const extended = _.extend({}, query, {
            associatedNameId: this.formData.sendToName.key,
            entityTypes: JSON.stringify({
                isIndividual: 'true'
            })
        });

        return extended;
    }

    toggleAttention(): void {
        this.formData.sendToAttentionName = null;
        this.formData.sendToAddress = null;
        this.formData.supplierMainContact = null;
    }

    defaultSendTo(): void {
        if (!this.formData.sendToName) {
            this.formData.sendToName = this.formData.supplierName;
            this.formData.sendToAddress = this.formData.supplierNameAddress;
            this.formData.sendToAttentionName = this.formData.supplierMainContact;
        }
    }

    setReason(): void {
        if (this.formData.restrictionKey === '') {
            this.formData.reasonCode = '';
            this.ngForm.form.controls.reasonForRestriction.disable();
        } else {
            if (this.isMaintainable) {
                this.ngForm.form.controls.reasonForRestriction.enable();
            } else {
                this.ngForm.form.controls.reasonForRestriction.disable();
            }
        }
        this.checkValidationAndEnableSave();
    }

    checkValidationAndEnableSave(): void {
        if (this.formData.restrictionKey !== undefined && this.formData.restrictionKey !== null && this.formData.restrictionKey !== '') {
            if (this.formData.reasonCode === '' || this.formData.reasonCode == null) {
                if (!this.ngForm.form.controls.reasonForRestriction.errors) {
                    this.ngForm.form.controls.reasonForRestriction.markAsTouched();
                    this.ngForm.form.controls.reasonForRestriction.markAsDirty();
                    this.ngForm.form.controls.reasonForRestriction.setErrors({ 'nameView.supplierDetails.reasonForRestrictionError': true });
                }
            } else {
                if (!!this.ngForm.form.controls.reasonForRestriction.errors) {
                    this.ngForm.form.controls.reasonForRestriction.setErrors(null);
                }
            }
            this.cdr.markForCheck();
        }

        if (this.ngForm.form.valid) {
            this.service.enableSave.next(true);
        } else {
            this.service.enableSave.next(false);
        }
        if (!this.isMaintainable) {
            this.service.enableSave.next(false);
        }
    }

    revert = (): void => {
        this.formData = {
            ...this.originalFormData
        };
        this.markFormPristine(this.ngForm);
        if (this.isHosted) {
            this.windowParentMessagingService.postLifeCycleMessage({
                action: 'onChange',
                target: 'supplierHost',
                payload: {
                    isDirty: false
                }
            });
        }
    };
}

export class SupplierDetailsTopic extends Topic {
    readonly key = 'supplierDetails';
    readonly title = 'nameview.supplierDetails.header';
    readonly component = SupplierDetailsComponent;
    constructor(public params: SupplierDetailsTopicParams) {
        super();
    }
}

export class SupplierDetailsTopicParams extends TopicParam {
}