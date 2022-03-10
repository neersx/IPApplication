import { DebtorWarningsComponent } from './debtor-warnings.component';

describe('DebtorWarningsComponent', () => {
    let component: DebtorWarningsComponent;
    beforeEach(() => {
        component = new DebtorWarningsComponent();
    });
    describe('onInit', () => {
        it('should show warnings count as 0 if no warnings or discounts or multi case debtor', () => {
            component.debtorWarnings = [];
            component.ngOnInit();
            expect(component.warningsCount).toBe(0);
            expect(component.warnings.length).toBe(0);
        });
        it('should show warnings count if warnings present', () => {
            component.debtorWarnings = [{ id: 1, warning: 'draftBillExist' }];
            component.ngOnInit();
            expect(component.warningsCount).toBe(1);
            expect(component.warnings.length).toBe(1);
            expect(component.warnings[0].detail).toBe('accounting.billing.step1.debtors.warnings');

            component.hasDiscounts = true;
            component.showMultiCase = true;
            component.ngOnInit();
            expect(component.warningsCount).toBe(3);
        });
    });
});