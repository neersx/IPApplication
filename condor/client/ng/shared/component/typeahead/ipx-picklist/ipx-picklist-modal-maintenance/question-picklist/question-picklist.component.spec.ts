import { ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { of } from 'rxjs/internal/observable/of';
import { QuestionPicklistComponent } from './question-picklist.component';

describe('QuestionPicklistComponent', () => {
    let component: QuestionPicklistComponent;
    let service: any;
    let cdRef: any;
    let questionPicklistService: any;
    let translate: any;

    beforeEach(() => {
        service = { maintenanceMetaData$: { getValue: jest.fn().mockReturnValue({}) }, modalStates$: { getValue: jest.fn() }, nextModalState: jest.fn() };
        cdRef = new ChangeDetectorRefMock();
        translate = new TranslateServiceMock();
        questionPicklistService = { getViewData: jest.fn().mockReturnValue(of({})),
            viewData$: of({ periodTypes: [{ userCode: 'D', periodType: 'Days' }, { userCode: 'M', periodType: 'Months' }, { userCode: 'Y', periodType: 'Years' }] }) };
        component = new QuestionPicklistComponent(service, cdRef, questionPicklistService, translate);
        component.entry = {
            code: 'ABCxyz',
            question: 'Question ABC xyz',
            instructions: null,
            yesNo: null,
            count: null,
            amount: null,
            text: null,
            staff: null,
            period: null,
            listType: null
        };
    });

    it('should create and call view data and initialise options', () => {
        expect(component).toBeTruthy();
        expect(questionPicklistService.getViewData).toHaveBeenCalledTimes(1);
        expect(component.generalResponseOptions).toBeDefined();
        expect(component.yesNoResponseOptions).toBeDefined();
    });

    describe('intialisation', () => {
        it('should initialise view properties', () => {
            service.viewData$ = of({});
            component.ngOnInit();
            expect(service.maintenanceMetaData$.getValue).toHaveBeenCalled();
            expect(component.form).toBeDefined();
        });
        it('should initialise the form with values', () => {
            component.togglePeriod = jest.fn();
            component.entry = {
                key: -999,
                code: 'ABCxyz',
                question: 'Question ABC xyz',
                instructions: 'Instruction for question',
                yesNo: 1,
                count: 2,
                amount: 2,
                text: 2,
                staff: 2,
                period: 4,
                listType: 123
            };
            service.viewData$ = of({ tableTypes: [{key: 123, value: 'Table ABC-123'}]});
            component.ngOnInit();
            expect(component.form.value).toEqual({
                code: 'ABCxyz',
                question: 'Question ABC xyz',
                instructions: 'Instruction for question',
                yesNo: 1,
                count: 2,
                amount: 2,
                text: 2,
                staff: 2,
                period: 4,
                list: 123
            });
            expect(component.key).toBe(-999);
            expect(component.togglePeriod).toHaveBeenCalled();
        });
        it('should disable period if count is Hide', () => {
            service.viewData$ = of({});
            component.ngOnInit();
            component.togglePeriod();
            expect(component.isPeriodDisabled).toBeTruthy();
            component.form.controls.count.setValue(0);
            component.togglePeriod();
            expect(component.isPeriodDisabled).toBeTruthy();
        });
        it('should enable period if count is not Hide', () => {
            service.viewData$ = of({});
            component.ngOnInit();
            component.togglePeriod();
            expect(component.isPeriodDisabled).toBeTruthy();
            component.form.controls.count.setValue(1);
            component.togglePeriod();
            expect(component.isPeriodDisabled).toBeFalsy();
            component.form.controls.count.setValue(2);
            component.togglePeriod();
            expect(component.isPeriodDisabled).toBeFalsy();
            component.form.controls.period.setValue(4);
            component.form.controls.count.setValue(20);
            component.togglePeriod();
            expect(component.isPeriodDisabled).toBeTruthy();
            expect(component.form.controls.period.value).toBeNull();
        });
    });
});
