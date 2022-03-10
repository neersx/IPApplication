import { CaseSearchHelperServiceMock, ChangeDetectorRefMock } from 'mocks';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { DesignElementComponent } from './design.element.component';
describe('DesignElementComponent', () => {
    let c: DesignElementComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        c = new DesignElementComponent(StepsPersistanceSeviceMock as any, CaseSearchHelperServiceMock as any, cdr as any);
        c.isExternal = false;
        viewData = {
            isExternal: false
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'designElement',
            title: 'designElement'
        };
    });

    it('should create the component', () => {
        expect(c).toBeTruthy();
    });

    it('initialises defaults', () => {
        expect(c.isExternal).toBe(viewData.isExternal);
    });

    it('should return Design Element filter criteria', () => {
        c.formData = {
            firmElement: 'firmid1234',
            firmElementOperator: '2',
            typeface: 'typeface123',
            typefaceOperator: '2'
        };

        const data = c.getFilterCriteria();
        expect(data.designElements.firmElement.operator).toEqual('2');
        expect(data.designElements.firmElement.value).toEqual('firmid1234');
        expect(data.designElements.typeface.operator).toEqual('2');
        expect(data.designElements.typeface.value).toEqual('typeface123');
    });
});