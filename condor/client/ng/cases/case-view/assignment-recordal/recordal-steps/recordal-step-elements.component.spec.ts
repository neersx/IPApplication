import { ChangeDetectorRefMock } from 'mocks';
import { BehaviorSubject } from 'rxjs';
import { RecordalStepElement, StepElements } from '../affected-cases.model';
import { RecordalStepElementComponent } from './recordal-step-elements.component';

describe('RecordalStepElementComponent', () => {
    let component: RecordalStepElementComponent;
    let service: {
        rowSelected$: BehaviorSubject<StepElements>;
        getRecordalStepElements(caseKey: number, stepId: number, recordalType: number): any;
        currentAddressChange$: BehaviorSubject<RecordalStepElement>;

    };
    let cdRef: ChangeDetectorRefMock;
    beforeEach(() => {
        const stepElements: Array<StepElements> = [{ stepId: 1, recordalType: 1 }];
        service = {
            rowSelected$: new BehaviorSubject<StepElements>({ stepId: 1 } as any),
            currentAddressChange$: new BehaviorSubject<RecordalStepElement>(null),
            getRecordalStepElements: jest.fn()
        };
        cdRef = new ChangeDetectorRefMock();
        component = new RecordalStepElementComponent(service as any, cdRef as any);
        component.isHosted = false;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
    it('should set rowSelected', done => {
        component.stepId = 1;
        service.rowSelected$.next = jest.fn();
        component.ngOnInit();
        service.rowSelected$
            .subscribe((val: any) => {
                expect(val).toEqual({ stepId: 1 });
                expect(component.stepId).toBe(1);
                done();
            });
    });
});