import { ChangeDetectionStrategy, Component, EventEmitter, OnInit, Output } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import * as _ from 'underscore';
import { WarningService } from '../warning-service';
import { CreditLimit, Restriction } from '../warnings-model';

@Component({
    selector: 'casenames-warnings',
    templateUrl: 'casenames-warnings.component.html',
    styleUrls: ['./casenames-warnings.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CasenamesWarningsComponent implements OnInit {

    @Output() private readonly btnClicked = new EventEmitter<boolean>();
    modalRef: BsModalRef;
    caseNames: Array<any>;
    name;
    debtorName;
    noOfDebtorsExceededCredit;
    namesWithRestrictions: Array<Restriction> = [];
    namesWithCreditLimits: Array<CreditLimit> = [];
    useNameOnlyTemplate;
    isPwdReqd = true;
    isBlockedState = false;
    formGroup: FormGroup;
    restrictOnWip: boolean;
    budgetCheckResult?: any;
    activeBudget: any;
    selectedEntryDate: Date = null;
    prepaymentCheckResult: any;
    hostId = null;
    isHosted = false;
    billingCapCheckResults: Array<any> = [];

    @Output() private readonly onBlocked = new EventEmitter<boolean>();

    constructor(private readonly formBuilder: FormBuilder,
                readonly warningService: WarningService,
                private readonly bsModalRef: BsModalRef, private readonly windowParentMessagingService: WindowParentMessagingService) {
        this.modalRef = bsModalRef;
    }

    ngOnInit(): void {
        this.isBlockedState = _.any(this.caseNames, cn => {
            return cn.caseName.blocked;
        });

        this.restrictOnWip = this.warningService.restrictOnWip;
        this.isPwdReqd = this.restrictOnWip && !this.isBlockedState && _.any(this.caseNames, cn => {
            return cn.caseName.requirePassword;
        });

        this.isHosted = !!this.hostId;
        this.createFormGroup();

        // if multiple same nameid's with diff nameTypes, change all their nametypes with a comma separated nametypes.
        this.makeCommaSeparatedNameTypes();

        this.initializeLimitsAndRestrictions();

        // resolve which template to be used
        this.resolveTemplate();
        this.activeBudget = !!this.budgetCheckResult ? this.budgetCheckResult.budget.revised || this.budgetCheckResult.budget.original : null;
        if (!!this.billingCapCheckResults && this.billingCapCheckResults.length > 0) {
            this.billingCapCheckResults.forEach(element => {
                element.periodTypeDescription = this.warningService.setPeriodTypeDescription(element);
            });
        }
    }

    resolveTemplate(): void {
        if (this.namesWithCreditLimits.length === 1 && this.namesWithRestrictions.length === 0) {
            this.name = this.namesWithCreditLimits[0];
            this.debtorName = this.namesWithCreditLimits[0].name;
            this.useNameOnlyTemplate = true;
        } else if (this.namesWithCreditLimits.length === 0 && this.namesWithRestrictions.length === 1) {
            this.name = this.namesWithRestrictions[0];
            this.debtorName = this.namesWithRestrictions[0].name;
            this.useNameOnlyTemplate = true;
        } else if ((this.namesWithCreditLimits.length === 1 && this.namesWithRestrictions.length === 1 && this.namesWithCreditLimits[0].nameKey === this.namesWithRestrictions[0].nameKey)) {
            const caseName = this.caseNames[0];
            this.name = { nameKey: caseName.caseName.id, name: caseName.caseName.displayName, description: caseName.caseName.debtorStatus, severity: caseName.caseName.severity, type: caseName.caseName.nameType, receivableBalance: this.namesWithCreditLimits[0].receivableBalance, creditLimit: this.namesWithCreditLimits[0].creditLimit, limitPercentage: this.namesWithCreditLimits[0].limitPercentage };
            this.debtorName = this.name.name;
            this.useNameOnlyTemplate = true;
        } else {
            this.useNameOnlyTemplate = false;
        }
    }

    initializeLimitsAndRestrictions(): void {
        const limitExceeded = _.uniq(_.filter(this.caseNames, (c) => {
            return c.creditLimitCheckResult && c.creditLimitCheckResult.exceeded;
        }), false, (cn) => {
            return cn.caseName.id;
        });
        _.map(limitExceeded, (c) => {
            this.namesWithCreditLimits.push({ nameKey: c.caseName.id, name: c.caseName.displayName, receivableBalance: c.creditLimitCheckResult.receivableBalance, creditLimit: c.creditLimitCheckResult.creditLimit, limitPercentage: c.creditLimitCheckResult.limitPercentage });
        });
        const restricted = _.uniq(_.filter(this.caseNames, (c) => {
            return c.caseName.debtorStatus;
        }), false, (cn) => {
            return cn.caseName.id;
        });
        _.map(restricted, (c) => {
            this.namesWithRestrictions.push({ nameKey: c.caseName.id, name: c.caseName.displayName, description: c.caseName.debtorStatus, severity: c.caseName.severity, type: c.caseName.nameType });
        });
    }

    createFormGroup(): FormGroup {
        this.formGroup = this.formBuilder.group({
            // tslint:disable-next-line: no-unbound-method
            pwd: ['', [Validators.required, this.passwordValidator]]
        });

        return this.formGroup;
    }

    makeCommaSeparatedNameTypes(): void {
        const groupedByIds = _.countBy(this.caseNames, cn => {
            return cn.caseName.id;
        });
        const nameTypes = [];
        for (const id in groupedByIds) {
            if (groupedByIds[id] > 1) {
                const duplicateNames = _.filter(this.caseNames, cn => cn.caseName.id === +id);
                duplicateNames.forEach(x => {
                    nameTypes.push(x.caseName.nameType);
                });
                const commaSeparatedNameTypes = nameTypes.join(', ');
                _.map(this.caseNames, cn => {
                    if (cn.caseName.id === +id) {
                        cn.caseName.nameType = commaSeparatedNameTypes;
                    }
                });
            }
        }
    }

    proceed(): void {
        if (this.isPwdReqd) {
            const nameWithPwdSet = this.caseNames.find(cn => cn.caseName.requirePassword === true);
            this.warningService.validate(nameWithPwdSet.caseName.id, this.formGroup.get('pwd').value)
                .subscribe((isAuth: boolean) => {
                    if (isAuth) {
                        if (this.isHosted) {
                            this.windowParentMessagingService.postLifeCycleMessage({
                                action: 'onChange',
                                target: this.hostId,
                                payload: {
                                    isProceed: true
                                }
                            });
                        } else {
                            this.modalRef.hide();
                            this.btnClicked.emit(true);
                        }

                        return;
                    }
                    const val = this.formGroup.get('pwd').value;
                    this.formGroup.get('pwd').setErrors({ invalidpassword: true }, { emitEvent: true });
                    this.formGroup.get('pwd').setValue(val);

                    return;
                });

                return;
        }
        if (this.isHosted) {
            this.windowParentMessagingService.postLifeCycleMessage({
                action: 'onChange',
                target: this.hostId,
                payload: {
                    isProceed: true
                }
            });
        } else {
            this.btnClicked.emit(true);
            this.modalRef.hide();
        }
    }

    passwordValidator(control: AbstractControl): boolean | any {
        if (!control.errors || !control.errors.invalidpassword) {
            return true;
        }

        return { invalidpassword: true };
    }

    cancel(): void {
        if (this.isHosted) {
            this.windowParentMessagingService.postLifeCycleMessage({
                action: 'onChange',
                target: this.hostId,
                payload: {
                    isProceed: false
                }
            });
        } else {
            this.btnClicked.emit(false);
            this.modalRef.hide();
        }
    }

    blocked(): void {
        if (this.isHosted) {
            this.windowParentMessagingService.postLifeCycleMessage({
                action: 'onChange',
                target: this.hostId,
                payload: {
                    isProceed: false
                }
            });
        } else {
            this.onBlocked.emit(this.isBlockedState);
            this.modalRef.hide();
        }
    }
}