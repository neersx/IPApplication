import { CaseSearchHelperServiceMock, ChangeDetectorRefMock } from 'mocks';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { OtherDetailsComponent } from '.';
import { SearchOperator } from '../../common/search-operators';
describe('OtherDetailsComponent', () => {
    let c: OtherDetailsComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    const caseHelpermock = new CaseSearchHelperServiceMock();
    let featureDetectionMock: any;
    caseHelpermock.buildStringFilter.mockReturnValue({ operator: '0', value: '1,2' });
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        featureDetectionMock = {
            hasSpecificRelease$: jest.fn()
        };
        c = new OtherDetailsComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, cdr as any, featureDetectionMock);
        c.isExternal = false;
        viewData = {
            isExternal: false,
            entitySizes: [ {key: 1, value: 'Large Entity'} ]
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'otherDetails',
            title: 'otherDetails'
        };
    });

    it('should create the component', () => {
        expect(c).toBeTruthy();
    });

    it('initialises topic data', () => {
        jest.spyOn(featureDetectionMock, 'hasSpecificRelease$');
        c.viewData = viewData;
        c.initTopicsData();
        expect(c.isExternal).toBe(viewData.isExternal);
        expect(c.entitySizes).toBe(viewData.entitySizes);
        expect(featureDetectionMock.hasSpecificRelease$).toHaveBeenCalledTimes(1);
    });

    it('should return Other Details criteria', () => {
        c.formData = {
            fileLocation: [{ key: 1 }, { key: 2 }],
            fileLocationOperator: '0'
        };

        const data = c.getFilterCriteria();
        expect(data.fileLocationKeys.operator).toEqual('0');
        expect(data.fileLocationKeys.value).toEqual('1,2');
    });
    it('should return entity size value', () => {
        c.formData = {
            entitySize: {key: 1},
            entitySizeOperator: '0'
        };

        const data = c.getFilterCriteria();
        expect(data.entitySize.value).toEqual(1);
        expect(data.entitySize.operator).toEqual('0');
    });
    it('should return proper values when operator exists for entity size', () => {
        c.formData = {
            entitySize: {key: 1},
            entitySizeOperator: '5'
        };

        const data = c.getFilterCriteria();
        expect(data.entitySize.value).toEqual(null);
        expect(data.entitySize.operator).toEqual('5');
    });
    it('set default EqualTo operator on Inherited from Name change', () => {
        c.formData = {
            forInstructionOperator: SearchOperator.exists
        };

        c.onInheritedFromNameChange();
        expect(c.formData.forInstructionOperator).toEqual(SearchOperator.equalTo);
    });
});