import { async } from '@angular/core/testing';
import { CaseSearchHelperServiceMock, ChangeDetectorRefMock } from 'mocks';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { StatusComponent } from '.';
describe('StatusComponent', () => {
    let c: StatusComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    const caseHelpermock = new CaseSearchHelperServiceMock();
    beforeEach(() => {
        caseHelpermock.buildStringFilter.mockReturnValue({ value: '123', operator: '2' });
        cdr = new ChangeDetectorRefMock();
        c = new StatusComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, cdr as any);
        c.isExternal = false;
        viewData = {
            isExternal: false
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'Status',
            title: 'Status'
        };
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));
    it('initialises defaults', () => {
        expect(c.isExternal).toBe(viewData.isExternal);
    });
    it('should update the case and renewal status correctly', () => {
        c.formData = {
            isPending: true,
            isRegistered: true,
            isDead: false,
            caseStatus: [{ key: 1, value: 'Value 1' }, { key: 2, value: 'Value 2' }],
            renewalStatus: [{ key: 1, value: 'Value 1' }, { key: 2, value: 'Value 2' }]
        };
        c.updateStatusInputs('pending');
        expect(c.formData.caseStatus).toEqual(null);
        expect(c.formData.renewalStatus).toEqual(null);
    });

});
