import { ChangeDetectionStrategy, Component, EventEmitter, Output } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable } from 'rxjs';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';
import { Period } from '../time-recording-model';

@Component({
    selector: 'change-entry-date',
    templateUrl: 'change-entry-date.component.html',
    styleUrls: ['change-entry-date.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class ChangeEntryDateComponent {
    @Output() private readonly saveClicked = new EventEmitter<Date>();
    newDate: Date;
    initialDate: any;
    item: any;
    canUpdate: boolean;
    isContinued: boolean;
    today: Date;
    openPeriods: Observable<Array<Period>>;
    constructor(private readonly modalRef: BsModalRef) {
        this.today = DateFunctions.getDateOnly(new Date());
    }

    onDateChanged = (event: any) => {
        if (!!event) {
            this.newDate = event;

            this.canUpdate = this.sameDates();
        }
    };

    isValidDate = (event: Date, openPeriods: Array<Period>, f: NgForm): boolean => {
        if (!!event && this.item.isPosted && !_.any(openPeriods, (p: Period) => p.isWithin(event))) {
            f.controls.newEntryDate.setErrors({ 'timeRecording.selectOpenPeriod': true });

            return false;
        }

        return true;
    };

    sameDates(): boolean {
        return this.newDate.toDateString() === this.initialDate.toDateString();
    }

    ok(): void {
        this.saveClicked.emit(this.newDate);
        this.modalRef.hide();
    }

    close(): void {
        this.modalRef.hide();
    }
}
