import { FormBuilder } from '@angular/forms';
import { BsModalServiceMock } from 'mocks';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { of } from 'rxjs';
import { WarningServiceMock } from '../warning.mock';
import { CasenamesWarningsComponent } from './casenames-warnings.component';

describe('CasenamesWarningsComponent', () => {
    let c: CasenamesWarningsComponent;
    let warningService: any;
    let formBuilder: FormBuilder;
    let bsModalService: any;
    let parentMsg: WindowParentMessagingServiceMock;

    beforeEach(() => {
        warningService = new WarningServiceMock();
        bsModalService = new BsModalServiceMock();
        formBuilder = new FormBuilder();
        parentMsg = new WindowParentMessagingServiceMock();
        c = new CasenamesWarningsComponent(formBuilder, warningService, bsModalService, parentMsg as any);
        c.formGroup = formBuilder.group({
            pwd: ['']
        });
    });

    describe('Casenames warnings', () => {
        it('should initialize name & debtor name properties when only one debtor has exceeded credit limit', () => {
            const debtor = 'Balloon Blast Ball Pty Ltd';
            c.caseNames = [{
                caseName: {
                    id: 10048,
                    displayName: debtor,
                    nameType: 'Debtor'
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: true
                }
            }, {
                caseName: {
                    id: 100,
                    displayName: debtor,
                    nameType: 'Debtor'
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: false
                }
            }];
            c.ngOnInit();
            expect(c.debtorName).toBe(debtor);
            expect(c.useNameOnlyTemplate).toBe(true);
        });
        it('should initialize name & debtor name properties when only one debtor has a restriction', () => {
            const debtor1 = 'Restricted Debtor';
            const debtor2 = 'Balloon Blast Ball Pty Ltd';
            c.caseNames = [{
                caseName: {
                    id: 10048,
                    displayName: debtor1,
                    nameType: 'Debtor',
                    debtorStatus: 'This debtor has restrictions',
                    enforceNameRestriction: true
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: false
                }
            }, {
                caseName: {
                    id: 100,
                    displayName: debtor2,
                    nameType: 'Debtor'
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: false
                }
            }];
            c.ngOnInit();
            expect(c.debtorName).toBe(debtor1);
            expect(c.useNameOnlyTemplate).toBe(true);
        });
        it('should initialize name & debtor name properties when the same debtor has restriction and exceeded credit limit ', () => {
            c.caseNames = [{
                caseName: {
                    id: 10048,
                    displayName: 'Balloon Blast Ball Pty Ltd',
                    nameType: 'Debtor',
                    debtorStatus: 'This debtor used to be good'
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: true
                }
            },
            {
                caseName: {
                    id: 987,
                    displayName: 'Asparagus',
                    nameType: 'Debtor'
                },
                creditLimitCheckResult: {
                    exceeded: false
                }
            }
            ];
            c.ngOnInit();
            expect(c.debtorName).toBe(c.caseNames[0].caseName.displayName);
            expect(c.useNameOnlyTemplate).toBe(true);
        });
        it('should fill the nameWithCreditLimits array with the caseNames info that has exceeded credit limit', () => {
            c.caseNames = [{
                caseName: {
                    id: 10048,
                    displayName: 'Balloon Blast Ball Pty Ltd',
                    nameType: 'Debtor'
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: true
                }
            },
            {
                caseName: {
                    id: 10048,
                    displayName: 'Balloon Blast Ball Pty Ltd',
                    nameType: 'Debtor'
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: false
                }
            }
            ];
            c.ngOnInit();
            expect(c.namesWithCreditLimits.length).toEqual(1);
        });
        it('should not assign the name & debtorName properties when the caseNames exceeded flag count is more than 1', () => {
            c.caseNames = [{
                caseName: {
                    id: 10048,
                    displayName: 'Balloon Blast Ball Pty Ltd',
                    nameType: 'Debtor'
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: true
                }
            },
            {
                caseName: {
                    id: 999,
                    displayName: 'Balloon Blast Ball Pty Ltd',
                    nameType: 'Debtor'
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: true
                }
            }
            ];
            c.ngOnInit();
            expect(c.name).toBe(undefined);
            expect(c.debtorName).toBe(undefined);
            expect(c.useNameOnlyTemplate).toBe(false);
        });
        it('should set period type description', () => {
            c.billingCapCheckResults = [{
                receivableBalance: 16531.13,
                creditLimit: 100,
                exceeded: true
            }, {
                receivableBalance: 2345.67,
                creditLimit: 200,
                exceeded: true
            }];
            c.caseNames = [{
                caseName: {
                    id: 10048,
                    displayName: 'debtor A',
                    nameType: 'Debtor'
                },
                creditLimitCheckResult: {
                    receivableBalance: 16531.13,
                    creditLimit: 100,
                    exceeded: true
                }
            }, {
                caseName: {
                    id: 100,
                    displayName: 'debtor B',
                    nameType: 'Debtor'
                }
            }];
            c.ngOnInit();
            expect(warningService.setPeriodTypeDescription.mock.calls[0][0]).toEqual(c.billingCapCheckResults[0]);
            expect(warningService.setPeriodTypeDescription.mock.calls[1][0]).toEqual(c.billingCapCheckResults[1]);
            expect(c.billingCapCheckResults[0].periodTypeDescription).toEqual('translated-period-value');
            expect(c.billingCapCheckResults[1].periodTypeDescription).toEqual('translated-period-value');
        });
    });

    describe('Comma separated method', () => {
        it('should change the payload to have a comma separated nametypes when there are multiple types for the same nameId', () => {
            c.caseNames = [
                { caseName: { id: 1, nameType: 'debtor' } },
                { caseName: { id: 1, nameType: 'owner' } },
                { caseName: { id: 1, nameType: 'instr' } }
            ];
            c.makeCommaSeparatedNameTypes();
            expect(c.caseNames[0].caseName.nameType).toContain(',');
        });
    });

    describe('Proceed', () => {
        it('should set form error when entered pwd is invalid', () => {
            bsModalService.hide = jest.fn(() => {
                return null;
            });
            c.restrictOnWip = true;
            c.caseNames = [{ restriction: { nameId: 'a' }, caseName: { requirePassword: true } }];
            c.isPwdReqd = true;
            c.warningService.validate = jest.fn().mockReturnValue(of(false));
            c.formGroup.get('pwd').setErrors = jest.fn();
            c.proceed();
            expect(c.formGroup.get('pwd').setErrors).toHaveBeenCalled();
        });

        it('should sent to pld web message to proceed', () => {
            c.restrictOnWip = true;
            c.caseNames = [{ restriction: { nameId: 'a' }, caseName: { requirePassword: true } }];
            c.isPwdReqd = false;
            c.warningService.validate = jest.fn().mockReturnValue(of(false));
            c.hostId = 'abcHost';
            c.isHosted = true;
            c.proceed();
            expect(parentMsg.postLifeCycleMessage).toHaveBeenCalledWith({
                action: 'onChange',
                target: c.hostId,
                payload: {
                    isProceed: true
                }
            });
        });
    });

    describe('initializeLimitsAndRestrictions method', () => {
        it('should set the limits and restrictions arrays with unique values', () => {
            c.caseNames = [
                { caseName: { id: 1, displayName: 'a' }, creditLimitCheckResult: { exceeded: true, receivableBalance: 1, creditLimit: 1 } },
                { caseName: { id: 1, displayName: 'a' }, creditLimitCheckResult: { exceeded: true, receivableBalance: 1, creditLimit: 1 } },
                { caseName: { id: 2, displayName: 'a' }, creditLimitCheckResult: { exceeded: true, receivableBalance: 1, creditLimit: 1 } },
                { caseName: { id: 3, displayName: 'a', debtorStatus: 'slow payer', severity: 'warning', enforceNameRestriction: true }, creditLimitCheckResult: { exceeded: true, receivableBalance: 1, creditLimit: 1 } },
                { caseName: { id: 3, displayName: 'a', debtorStatus: 'slow payer', severity: 'warning', enforceNameRestriction: true }, creditLimitCheckResult: { exceeded: true, receivableBalance: 1, creditLimit: 1 } },
                { caseName: { id: 4, displayName: 'a', debtorStatus: 'very slow payer', severity: 'warning', enforceNameRestriction: false }, creditLimitCheckResult: { exceeded: true, receivableBalance: 1, creditLimit: 1 } }
            ];
            c.initializeLimitsAndRestrictions();
            expect(c.namesWithCreditLimits.length).toBe(4);
            expect(c.namesWithRestrictions.length).toBe(2);
            // to ensure uniqueness
            expect(c.namesWithCreditLimits.filter(x => x.nameKey === 1).length).toBe(1);
            expect(c.namesWithCreditLimits.filter(x => x.nameKey === 3).length).toBe(1);
            expect(c.namesWithCreditLimits.filter(x => x.nameKey === 4).length).toBe(1);
        });
    });

    describe('resolveTemplate method', () => {
        it('should set to use nameOnly template when there\'s only one debtor exceeded credit limit and has no restrictions', () => {
            c.namesWithCreditLimits = [
                { name: 'a', receivableBalance: 1, creditLimit: 1, nameKey: 1 }
            ];
            c.resolveTemplate();
            expect(c.useNameOnlyTemplate).toBe(true);
            expect(c.name).toBe(c.namesWithCreditLimits[0]);
            expect(c.debtorName).toBe(c.namesWithCreditLimits[0].name);
        });

        it('should set to use nameOnly template when there\'s only one debtor exceeded restrictions but has no creditLimit', () => {
            c.namesWithRestrictions = [
                { name: 'a', nameKey: 1, type: 'warning', description: 'slow payer', severity: 'warning' }
            ];
            c.resolveTemplate();
            expect(c.useNameOnlyTemplate).toBe(true);
            expect(c.name).toBe(c.namesWithRestrictions[0]);
            expect(c.debtorName).toBe(c.namesWithRestrictions[0].name);
        });

        it('should set to use nameOnly template when there\'s only one debtor exceeded restrictions and creditLimits', () => {
            c.caseNames = [
                {
                    caseName: {
                        caseName: { id: 1, displayName: 'a', debtorStatus: 'a', severity: 'a', nameType: 'a' }
                    },
                    creditLimitCheckResult: { receivableBalance: 1, creditLimit: 1 }
                }
            ];
            c.namesWithRestrictions = [
                { name: 'a', nameKey: 1, type: 'warning', description: 'slow payer', severity: 'warning' }
            ];
            c.namesWithCreditLimits = [
                { name: 'a', receivableBalance: 1, creditLimit: 1, nameKey: 1 }
            ];
            c.resolveTemplate();
            expect(c.useNameOnlyTemplate).toBe(true);
        });
        it('should not set nameOnly template when there\'s more than one debtors', () => {
            c.caseNames = [
                {
                    caseName: {
                        caseName: { id: 1, displayName: 'a', debtorStatus: 'a', severity: 'a', nameType: 'a' }
                    },
                    creditLimitCheckResult: { receivableBalance: 1, creditLimit: 1 }
                },
                {
                    caseName: {
                        caseName: { id: 1, displayName: 'a', debtorStatus: 'a', severity: 'a', nameType: 'a' }
                    },
                    creditLimitCheckResult: { receivableBalance: 1, creditLimit: 1 }
                }
            ];
            c.resolveTemplate();
            expect(c.useNameOnlyTemplate).toBe(false);
        });
    });
});
