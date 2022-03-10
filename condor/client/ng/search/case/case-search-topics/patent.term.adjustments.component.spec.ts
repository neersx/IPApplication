import { async } from '@angular/core/testing';
import { CaseSearchHelperServiceMock, CaseTopicsDataService, ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs/internal/observable/of';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { PatentTermAdjustmentsComponent } from './patent.term.adjustments.component';
describe('PatentTermAdjustmentsComponent', () => {
    let c: PatentTermAdjustmentsComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    const caseHelpermock = new CaseSearchHelperServiceMock();
    const caseTopicService = new CaseTopicsDataService();
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        caseHelpermock.buildStringFilter.mockReturnValue({ value: '123', operator: '2' });
        c = new PatentTermAdjustmentsComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, cdr as any);
        viewData = {};
        c.topic = {
            params: {
                viewData
            },
            key: 'patentTermAdjustments',
            title: 'patentTermAdjustments'
        };
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));
    it('should return Patent Term Adjustment Correctly', () => {
        c.formData = {
            ptaDiscrepancies: 1,
            suppliedPtaOperator: '7',
            fromSuppliedPta: 1,
            toSuppliedPta: 10,
            fromPtaDeterminedByUs: 11,
            toPtaDeterminedByUs: 20,
            determinedByUsOperator: '8'
        };
        const data = c.getFilterCriteria();
        caseTopicService.getTopicsDefaultViewModel.mockReturnValue(of([]));
        caseTopicService.getTopicExistingViewModel.mockReturnValue(of([]));
        expect(data).toBeDefined();
        expect(data.patentTermAdjustments.hasDiscrepancy).toEqual(1);
        expect(data.patentTermAdjustments.ipOfficeAdjustment.fromDays).toEqual(1);
        expect(data.patentTermAdjustments.ipOfficeAdjustment.toDays).toEqual(10);
        expect(data.patentTermAdjustments.ipOfficeAdjustment.operator).toEqual('7');
        expect(data.patentTermAdjustments.calculatedAdjustment.fromDays).toEqual(11);
        expect(data.patentTermAdjustments.calculatedAdjustment.toDays).toEqual(20);
        expect(data.patentTermAdjustments.calculatedAdjustment.operator).toEqual('8');
    });
});
