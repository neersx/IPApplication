import { BillingStepsPersistanceService } from './billing-steps-persistance.service';

describe('BillingStepsPersistanceService', () => {
    let service: BillingStepsPersistanceService;

    beforeEach(() => {
        service = new BillingStepsPersistanceService();
    });

    it('should be created', () => {
        expect(service).toBeTruthy();
    });

    describe('getStepData', () => {
        it('should return the step data matched to the stepId', () => {
            const stepData = service.getStepData(1);
            expect(stepData.id).toEqual(1);
            expect(stepData.isDefault).toBeTruthy();
            expect(stepData.selected).toBeTruthy();
        });
    });
});
