import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { BillingStepsPersistanceService } from '../billing-steps-persistance.service';
import { BillingWizardStep } from '../billing.model';

@Component({
    selector: 'ipx-billing-wizard-multistep',
    templateUrl: './billing-wizard-multistep.component.html',
    styleUrls: ['./billing-wizard-multistep.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class BillingWizardMultistepComponent implements OnInit {

    constructor(private readonly cdr: ChangeDetectorRef, private readonly billingStepsService: BillingStepsPersistanceService,
        private readonly ipxNotificationService: IpxNotificationService) {
    }
    steps: Array<BillingWizardStep>;
    currentStep: BillingWizardStep;
    ngOnInit(): void {
        const firstStep = {
            id: 1,
            selected: true,
            title: 'accounting.billing.step1.title',
            isDefault: true
        };
        const secondStep = {
            id: 2,
            selected: false,
            title: 'accounting.billing.step2.title',
            isDefault: false
        };
        const thirdStep = {
            id: 3,
            selected: false,
            title: 'accounting.billing.step3.title',
            isDefault: false
        };
        const fourthStep = {
            id: 4,
            selected: false,
            title: 'accounting.billing.step4.title',
            isDefault: false
        };
        const fifthStep = {
            id: 5,
            selected: false,
            title: 'accounting.billing.step5.title',
            isDefault: false
        };
        const sixthStep = {
            id: 6,
            selected: false,
            title: 'accounting.billing.step6.title',
            isDefault: false
        };
        this.steps = [firstStep];

        this.steps.push(secondStep);
        this.steps.push(thirdStep);
        this.steps.push(fourthStep);
        this.steps.push(fifthStep);
        this.steps.push(sixthStep);
        this.currentStep = firstStep;
    }

    goTo = (step: number) => {
        if (step === this.currentStep.id) {

            return;
        }
        if (this.currentStep.id === 1) {
            const data = this.billingStepsService.getStepData(1);
            if (data.stepData.openItem && data.stepData.openItem.OpenItemNo) {
                const firstDebtor = data.stepData.debtorData[0];
                firstDebtor.DebtorCheckbox = true;
            }
            if (data && data.stepData && data.stepData.caseData && data.stepData.caseData.length > 0) {
                const anyDebtorAssigned = _.some(data.stepData.debtorData, (item: any) => {

                    return item.DebtorCheckbox;
                });
                if (!anyDebtorAssigned) {
                    this.displayStepError();

                    return;
                }
            } else if (!(data && data.stepData && data.stepData.debtorData && data.stepData.debtorData.length > 0)) {
                this.displayStepError();

                return;
            }

            if (!data.stepData.entity) {
                this.ipxNotificationService.openAlertModal('modal.unableToComplete', 'accounting.billing.step1.entityError');

                return;
            }
        }
        this.steps.map(v => v.selected = false);
        this.steps[step - 1].selected = true;
        this.currentStep = this.steps[step - 1];
        this.billingStepsService.changeStep$.next(this.currentStep);
        this.cdr.detectChanges();
    };

    displayStepError = (): void => {
        this.ipxNotificationService.openAlertModal('modal.unableToComplete', 'accounting.billing.step1.debtorError');
    };

    trackByFn = (index: number, step: BillingWizardStep): any => {
        return step;
    };
}