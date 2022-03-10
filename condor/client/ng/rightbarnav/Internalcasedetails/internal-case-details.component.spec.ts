import { ChangeDetectorRefMock } from 'mocks';
import { InternalCaseDetailsComponent } from './internal-case-details.component';

describe('InternalCaseDetailsComponent', () => {
    let component: InternalCaseDetailsComponent;
    let changeDetectorRefMock: ChangeDetectorRefMock;

    beforeEach(() => {
        changeDetectorRefMock = new ChangeDetectorRefMock();
        component = new InternalCaseDetailsComponent(changeDetectorRefMock as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

});
