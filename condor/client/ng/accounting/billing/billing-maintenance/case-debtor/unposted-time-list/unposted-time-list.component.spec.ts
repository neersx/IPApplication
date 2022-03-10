import { ChangeDetectorRefMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { UnpostedTimeListComponent } from './unposted-time-list.component';

describe('CaseDebtorComponent', () => {
    let component: UnpostedTimeListComponent;
    let cdr: ChangeDetectorRefMock;
    let modalService: ModalServiceMock;
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        modalService = new ModalServiceMock();
        component = new UnpostedTimeListComponent(cdr as any, modalService as any);
        (component as any).sbsModalRef = {
            hide: jest.fn()
        } as any;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('initialize component', () => {
        it('set initial parameters', () => {
            jest.spyOn(component, 'buildGridOptions');
            component.ngOnInit();
            expect(component.buildGridOptions).toHaveBeenCalled();
        });
    });

    it('should call the cancel', () => {
        component.cancel();
        expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
    });
});