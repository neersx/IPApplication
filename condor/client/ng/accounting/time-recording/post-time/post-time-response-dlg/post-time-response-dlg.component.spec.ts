import { BsModalServiceMock } from 'mocks';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { PostTimeResponseDlgComponent } from './post-time-response-dlg.component';

describe('PostTimeResponseDlgComponent', () => {
    let c: PostTimeResponseDlgComponent;
    let bsModalService: any;
    let modalRef: BsModalRef;
    let translateService: any;
    let localDatePipe: any;

    beforeEach(() => {
        bsModalService = new BsModalServiceMock();
        modalRef = new BsModalRef();
        modalRef.hide = jest.fn();
        translateService = { instant: jest.fn() };
        localDatePipe = { transform: jest.fn() };
        c = new PostTimeResponseDlgComponent(modalRef, translateService, localDatePipe);
    });

    describe('Cancel dialog', () => {
        it('should close the modal', () => {
            c.modalRef.hide = jest.fn();
            c.ok();
            expect(c.modalRef.hide).toHaveBeenCalled();
        });
    });

    describe('initialisation', () => {
        it('does not set the alert if there are no errors', () => {
            c.ngOnInit();
            expect(c.alert).toBeUndefined();
        });
        it('sets the alert message where available', () => {
            translateService.instant = jest.fn().mockReturnValue('There is an error');
            c.error = {alertID: 'AC13', contextArguments: ['2000-01-01']};
            c.ngOnInit();
            expect(c.alert).toBe('There is an error');
        });
    });
});
