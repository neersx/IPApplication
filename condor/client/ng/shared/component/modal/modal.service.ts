import { Injectable, TemplateRef, Type } from '@angular/core';
import { KeyBoardShortCutService } from 'core/keyboardshortcut.service';
import { BsModalRef, BsModalService, ModalOptions } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { finalize, take } from 'rxjs/operators';

export class HideEvent {
    readonly isCancelOrEscape: boolean;

    constructor(readonly reason?: string) {
        this.isCancelOrEscape = reason === 'esc' || reason === 'backdrop-click';
    }
}
@Injectable()
export class IpxModalService {
    modalRef: BsModalRef;
    fromNotificationService: boolean;
    private readonly onHide: Subject<HideEvent> = new Subject<HideEvent>();
    readonly onHide$ = this.onHide.asObservable();

    constructor(private readonly bsModalService: BsModalService,
        private readonly keyBoardShortCutService: KeyBoardShortCutService) {
        this.fromNotificationService = false;
    }

    openModal = (content: string | TemplateRef<any> | Type<any>, config?: ModalOptions, notificationService = false): BsModalRef => {
        this.fromNotificationService = notificationService;
        this.bsModalService.onShow.pipe(take(1)).subscribe(() => {
            if (!this.fromNotificationService) {
                this.keyBoardShortCutService.push();
            }
        });

        this.bsModalService.onHide.pipe(take(1), finalize(() => {
            this.fromNotificationService = false;
            this.modalRef = null;
        })).subscribe((reason: string) => {
            this.keyBoardShortCutService.pop();

            this.onHide.next(new HideEvent(reason));
        });

        this.modalRef = this.bsModalService.show(content, config);

        return this.modalRef;
    };
}