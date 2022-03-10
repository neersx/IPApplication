import { DebtorInstructionsComponent } from './debtor-instructions.component';

describe('DebtorInstructionsComponent', () => {
    let component: DebtorInstructionsComponent;
    beforeEach(() => {
        component = new DebtorInstructionsComponent();
    });
    describe('onInit', () => {
        it('should not show instructions if not preent', () => {
            component.ngOnInit();
            expect(component.instructionsLabel.length).toBe(0);
        });
        it('should show instructions', () => {
            component.instructions = 'Instructions';
            component.ngOnInit();
            expect(component.instructionsLabel.length).toBe(1);
            expect(component.instructionsLabel[0].detail).toBe('accounting.billing.step1.debtors.instructions');
        });
    });
});