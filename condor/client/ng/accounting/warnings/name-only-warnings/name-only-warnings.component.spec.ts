import { FormBuilder } from '@angular/forms';
import { BsModalServiceMock } from 'mocks';
import { of } from 'rxjs';
import { WarningServiceMock } from '../warning.mock';
import { NameOnlyWarningsComponent } from './name-only-warnings.component';

describe('NameOnlyWarningsComponent', () => {
    let c: NameOnlyWarningsComponent;
    let warningService: any;
    let formBuilder: FormBuilder;
    let bsModalService: any;

    beforeEach(() => {
        warningService = new WarningServiceMock();
        bsModalService = new BsModalServiceMock();
        formBuilder = new FormBuilder();
        c = new NameOnlyWarningsComponent(formBuilder, warningService, bsModalService);
        c.formGroup = formBuilder.group({
            pwd: ['']
        });
    });

    describe('Name only warnings', () => {
        beforeEach(() => {
            c.name = {
                creditLimitCheckResult: {
                    receivableBalance: 45378.6,
                    creditLimit: 500,
                    exceeded: true
                },
                displayName: 'disp name',
                restriction: {
                    requirePassword: false,
                    blocked: true
                },
                billingCapCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: false
                }
            };
        });
        it('should initialize name & debtor name properties and set restrictOnWip as per debtorWarningService', () => {
            c.warningService.restrictOnWip = true;
            c.ngOnInit();
            expect(c.debtorName).toBe('disp name');
            expect(c.isPwdReqd).toBe(false);
            expect(c.isBlockedState).toBe(true);
            expect(c.restrictOnWip).toBe(true);
        });

        it('should set form error when entered pwd is invalid', () => {
            c.restrictOnWip = true;
            c.isPwdReqd = true;
            c.warningService.validate = jest.fn().mockReturnValue(of(false));
            c.formGroup.get('pwd').setErrors = jest.fn();
            c.proceed();
            expect(c.formGroup.get('pwd').setErrors).toHaveBeenCalled();
        });
        it('should set period type description', () => {
            c.ngOnInit();
            expect(warningService.setPeriodTypeDescription).toHaveBeenCalledWith(c.name.billingCapCheckResult);
            expect(c.name.billingCapCheckResult.periodTypeDescription).toEqual('translated-period-value');
        });
    });
});
