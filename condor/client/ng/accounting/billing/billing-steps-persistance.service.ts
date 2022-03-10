import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';
import { BillingWizardStep } from './billing.model';

@Injectable()
export class BillingStepsPersistanceService {
    changeStep$: BehaviorSubject<any> = new BehaviorSubject<any>(null);
    billingSteps: Array<BillingWizardStep> = [];

    constructor() {
        this.initializeSteps();
    }

    initializeSteps = () => {
        this.billingSteps = [
            {
                id: 1,
                selected: true,
                isDefault: true,
                title: 'accounting.billing.step1.taskMenu.mainCase',
                stepData: {
                    itemDate: null,
                    entity: null,
                    raisedBy: null,
                    useRenewalDebtor: null,
                    currentAction: null,
                    language: null,
                    languageId: null,
                    caseData: null,
                    debtorData: null,
                    isCaseChanged: false,
                    isDebtorChanged: false
                }
            }, {
                id: 2,
                selected: false,
                isDefault: false,
                title: '',
                stepData: null
            }, {
                id: 3,
                selected: false,
                isDefault: false,
                title: '',
                stepData: {}
            }, {
                id: 4,
                selected: false,
                isDefault: false,
                title: '',
                stepData: null
            }, {
                id: 5,
                selected: false,
                isDefault: false,
                title: '',
                stepData: null
            }
        ];
    };

    getStepData = (stepId: number): BillingWizardStep => {
        const stepData = _.first(
            _.filter(this.billingSteps, (step: any) => {
                return step.id === stepId;
            })
        );

        return stepData;
    };
}