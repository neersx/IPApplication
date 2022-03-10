import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { HideEvent } from 'shared/component/modal/modal.service';
import { BsModalRefMock } from './bs-modal.service.mock';

export class NotificationServiceMock {
    modalRef: BsModalRef = new BsModalRefMock();
    modalService = jest.fn();
    openModal = jest.fn();
    openConfirmationModal = jest.fn().mockReturnValue(this.modalRef);
    openDeleteConfirmModal = jest.fn().mockReturnValue(this.modalRef);
    openAlertModal = jest.fn();
    openDiscardModal = jest.fn();
    success = jest.fn();
    info = jest.fn();
    confirmDelete = jest.fn().mockReturnValue(true).mockReturnValue({ then: jest.fn().mockReturnValue(true) });
    confirm = jest.fn().mockReturnValue({ then: jest.fn().mockReturnValue(true) });
    alert = jest.fn();
    ieRequired = jest.fn();
    get onHide$(): Observable<HideEvent> {
        return of();
    }
}

export class IpxNotificationServiceMock {
    modalRef: BsModalRef = new BsModalRefMock();
    openConfirmationModal = jest.fn().mockImplementation(() => { return this.modalRef; });
    openAlertModal = jest.fn().mockImplementation(() => { return this.modalRef; });
    openAlertListModal = jest.fn().mockImplementation(() => { return this.modalRef; });
    openWarningModal = jest.fn().mockImplementation(() => { return this.modalRef; });
    openDeleteConfirmModal = jest.fn().mockImplementation(() => { return this.modalRef; });
    openDiscardModal = jest.fn().mockImplementation(() => { return this.modalRef; });
    success = jest.fn();
    ieRequired = jest.fn();
    openInfoModal = jest.fn().mockImplementation(() => { return this.modalRef; });
    get onHide$(): Observable<HideEvent> {
        return of<HideEvent>(new HideEvent('esc')).pipe(delay(500));
    }
}