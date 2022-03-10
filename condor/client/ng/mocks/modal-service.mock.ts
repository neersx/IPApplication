import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { HideEvent } from 'shared/component/modal/modal.service';
import { BsModalRefMock } from './bs-modal.service.mock';

export class ModalServiceMock {
    content: any;
    readonly modalRef: BsModalRef = new BsModalRefMock();
    openModal = jest.fn().mockImplementation(() => {
        if (!!this.content) {
            this.modalRef.content = { ...this.modalRef.content, ...this.content };
        }

        return this.modalRef;
    });

    get onHide$(): Observable<HideEvent> {
        return this.returnValueonHide$;
    }
    returnValueonHide$: Observable<HideEvent>;

    constructor() {
        this.returnValueonHide$ = of<HideEvent>(new HideEvent('esc')).pipe(delay(500));
    }
}