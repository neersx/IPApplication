import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { DebtorSplit, TimeEntry } from '../time-recording-model';

@Component({
    selector: 'ipx-debtor-splits-component',
    templateUrl: 'debtor-splits.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DebtorSplitsComponent {

    timeEntry: TimeEntry;
    debtorSplits: Array<DebtorSplit>;
    modalRef: BsModalRef;

    constructor(private readonly bsModalRef: BsModalRef) {
        this.modalRef = bsModalRef;
    }

    trackDebtorSplitsBy = (index: number, item: DebtorSplit): number => {
        return item.debtorNameNo;
    };

    close(): void {
        this.modalRef.hide();
    }
}
