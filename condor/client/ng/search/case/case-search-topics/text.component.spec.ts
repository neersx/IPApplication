import { async } from '@angular/core/testing';
import { CaseSearchHelperServiceMock, ChangeDetectorRefMock } from 'mocks';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { TextComponent } from '.';
describe('TextComponent', () => {
    let c: TextComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    const caseHelpermock = new CaseSearchHelperServiceMock();
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        caseHelpermock.isFilterApplicable.mockReturnValue({ operator: '0', typeKey: 'typeCode', text: 'text' });
        c = new TextComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, cdr as any);
        c.textTypes = [{ key: 'a' }];
        viewData = {
            isExternal: false,
            textTypes: [{ key: 'a' }]
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'Text',
            title: 'Text'
        };
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));

    it('initialises defaults', () => {
        expect(c.textTypes).toEqual(viewData.textTypes);
    });

    it('should return Case Text Group Correctly', () => {
        c.formData = {
            textTypeOperator: '0',
            textType: 'typeCode',
            textTypeValue: 'text'
        };
        const data = c.getFilterCriteria();
        expect(data).toBeDefined();
        expect(data.caseTextGroup).toEqual({
            caseText: [{
                operator: '0',
                typeKey: 'typeCode',
                text: 'text'
            }]
        });
    });

    it('should generate Case Text Keyword Correctly', () => {
        caseHelpermock.buildStringFilterFromTypeahead.mockReturnValue('ACDC');
        c = new TextComponent(StepsPersistanceSeviceMock as any, caseHelpermock as any, cdr as any);
        c.formData = {
            keywordOperator: '0',
            keywordValue: { code: 'ACDC', value: 'acdc' }
        };
        const data = c.buildKeyword(c.formData);
        expect(data).toEqual('ACDC');
    });
});