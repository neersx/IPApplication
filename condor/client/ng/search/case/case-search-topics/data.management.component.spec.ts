import { async } from '@angular/core/testing';
import { CaseSearchHelperServiceMock, ChangeDetectorRefMock } from 'mocks';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { DataManagementComponent } from '.';
describe('DataManagementComponent', () => {
    let c: DataManagementComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    const caseHelpermock = new CaseSearchHelperServiceMock();
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        c = new DataManagementComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, cdr as any);
        c.isExternal = false;
        c.sentToCpaBatchNo = [{ batchNo: 101 }, { batchNo: 102 }];
        viewData = {
            isExternal: false,
            sentToCpaBatchNo: [{ batchNo: 101 }, { batchNo: 102 }]
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'dataManagement',
            title: 'dataManagement'
        };
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));

    it('initialises defaults', () => {
        expect(c.isExternal).toEqual(viewData.isExternal);
        expect(c.sentToCpaBatchNo).toEqual(viewData.sentToCpaBatchNo);
    });

    it('should return Data Management filter criteria', () => {
        c.formData = {
            batchIdentifier: 'test',
            dataSource: {
                key: 1,
                code: 'abc',
                value: 'abc'
            }
        };

        const spyCaseSearchHeloperService = jest.spyOn(caseHelpermock, 'buildStringFilter');
        const data = c.getFilterCriteria();
        expect(spyCaseSearchHeloperService).toHaveBeenCalled();
        expect(data).toBeDefined();
    });
});