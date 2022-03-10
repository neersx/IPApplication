import { BillingServiceMock } from 'accounting/billing/billing.mocks';
import { DebtorCopiesToComponent } from './debtor-copies-to.component';

describe('DebtorCopiesToComponent', () => {
    let component: DebtorCopiesToComponent;
    let service: BillingServiceMock;
    beforeEach(() => {
        service = new BillingServiceMock();
        component = new DebtorCopiesToComponent(service as any);
        component.copiesTo = [];
    });
    describe('onInit', () => {
        it('show copies To Name if empty', () => {
            component.ngOnInit();
            expect(component.copiesToLabel.length).toBe(1);
            expect(component.copiesToLabel[0].detail).toBe('accounting.billing.step1.debtors.copiesToNames');
            expect(component.copiesToCount.value).toBe(0);
        });
    });
});