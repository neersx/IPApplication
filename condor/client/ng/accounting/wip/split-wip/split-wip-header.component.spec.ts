import { TranslateServiceMock } from 'mocks';
import { SplitWipHeaderComponent, WipCategoryCode } from './split-wip-header.component';
import { SplitWipData } from './split-wip.model';

describe('SplitWipHeaderComponent', () => {
    let component: SplitWipHeaderComponent;
    let translate: TranslateServiceMock;

    beforeEach(() => {
        translate = new TranslateServiceMock();
        component = new SplitWipHeaderComponent(translate as any);

        const wipData: SplitWipData = {
            localAmount: 500,
            foreignBalance: 50,
            localValue: 500,
            foreignValue: 349,
            foreignCurrency: 'USD',
            caseReference: '1234',
            staffName: 'staff',
            narrativeCode: 'N',
            narrativeKey: 5,
            wipCategoryCode: 'W',
            wipDescription: 'Description',
            wipCode: 'AC',
            wipSeqKey: 1,
            entityKey: 123456,
            responsibleName: '',
            balance: 500,
            isCreditWip: false,
            localCurrency: 'AUD',
            exchRate: 1.5,
            localDeciamlPlaces: 2,
            foreignDecimalPlaces: 2,
            transDate: new Date(),
            transKey: 123,
            responsibleNameCode: 'RS'
        };
        component.splitWipData = wipData;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
    it('should initialize component', () => {
        component.ngOnInit();
        expect(component.isForeignCurrency).toBeTruthy();
    });

    it('should call set ReasonDirty', () => {
        component.reasonForm = {
            control: {
                controls: {
                    reason: {
                        markAsDirty: jest.fn(),
                        markAsTouched: jest.fn()
                    }
                }
            }
        };
        component.setReasonDirty();
        expect(component.reasonForm.control.controls.reason.markAsDirty).toHaveBeenCalled();
        expect(component.reasonForm.control.controls.reason.markAsTouched).toHaveBeenCalled();
    });

    it('should call getWipCategoryLabel', () => {
        component.getWipCategoryLabel(WipCategoryCode.Disbursement);
        expect(translate.instant).toBeCalledWith('wip.splitWip.disbursement');
    });

});