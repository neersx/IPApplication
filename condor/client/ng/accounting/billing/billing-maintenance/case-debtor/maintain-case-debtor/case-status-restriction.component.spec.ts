import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { CaseStatusRestrictionComponent } from './case-status-restriction.component';

describe('CaseStatusRestrictionComponent', () => {
    let component: CaseStatusRestrictionComponent;
    let modelRef: BsModalRefMock;
    let cdr: ChangeDetectorRefMock;
    beforeEach(() => {
        modelRef = new BsModalRefMock();
        cdr = new ChangeDetectorRefMock();
        component = new CaseStatusRestrictionComponent(cdr as any, modelRef as any);
    });
    it('should create', () => {
        expect(component).toBeTruthy();
    });
    it('set initial parameters', () => {
        jest.spyOn(component, 'buildGridOptions');
        component.ngOnInit();
        expect(component.buildGridOptions).toHaveBeenCalled();
    });
    it('should hide modal on cancel', () => {
        component.onClose$.next = jest.fn();
        component.cancel();
        expect(modelRef.hide).toBeCalled();
        expect(component.onClose$.next).toBeCalled();
    });
});