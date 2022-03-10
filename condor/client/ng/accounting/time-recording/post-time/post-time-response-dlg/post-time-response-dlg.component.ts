import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';

@Component({
    selector: 'post-time-response-dlg',
    templateUrl: 'post-time-response-dlg.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PostTimeResponseDlgComponent implements OnInit {
    modalRef: BsModalRef;
    rowsPosted: number;
    rowsIncomplete: number;
    hasOfficeEntityError: boolean;
    hasError: boolean;
    error: any;
    alert: string;

    constructor(private readonly bsModalRef: BsModalRef, private readonly translate: TranslateService, private readonly localDatePipe: LocaleDatePipe) {
        this.modalRef = this.bsModalRef;
    }

    ngOnInit(): void {
        if (this.error) {
            const dateParam = this.error.contextArguments.length > 0 ? new Date(this.error.contextArguments[0]) : null;
            this.alert = this.translate.instant(`accounting.errors.${this.error.alertID}`, { value: !!dateParam ? this.localDatePipe.transform(dateParam, null) : null });
        }
    }

    ok(): void {
        this.modalRef.hide();
    }
}
