import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { BsModalRef, BsModalService } from 'ngx-bootstrap/modal';

@Component({
    selector: 'ipx-info',
    templateUrl: 'ipx-info.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxInfoComponent {
    modalRef: BsModalRef;
    title = '';
    showCheckBox = true;
    info = '';
    @Input() chkBoxLabel = '';
    @Input() displayClose = true;
    @Output() private readonly okClicked = new EventEmitter<boolean>();
    isChecked = false;

    constructor(private readonly bsModalRef: BsModalRef) {
        this.modalRef = bsModalRef;
    }

    ok(): void {
        this.okClicked.emit(this.isChecked);
        this.modalRef.hide();
    }

    close(): void {
        this.modalRef.hide();
    }
}
