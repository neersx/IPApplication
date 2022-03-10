
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { ThirdPartySoftwareLicensesComponent } from './thirdpartysoftwarelicenses.component';

describe('ThirdpartysoftwarelicensesComponent', () => {
    let component: ThirdPartySoftwareLicensesComponent;

    beforeEach((() => {
        component = new ThirdPartySoftwareLicensesComponent(new BsModalRefMock() as any, new ChangeDetectorRefMock() as any);
    }));

    it('should component initialize', () => {
        expect(component).toBeTruthy();
    });

    it('should component initialize', () => {
        component.close();
        // tslint:disable-next-line: no-unbound-method
        expect(component.modalService.hide).toHaveBeenCalled();
    });

    it('should build hyperlinks where possible', () => {
        component.credits = ['a [http://go.to/a', 'b'];
        component.ngOnInit();
        expect(component.lines[0]).toEqual({ oss: 'a', link: 'http://go.to/a' });
        expect(component.lines[1]).toEqual({ oss: 'b' });
    });
});