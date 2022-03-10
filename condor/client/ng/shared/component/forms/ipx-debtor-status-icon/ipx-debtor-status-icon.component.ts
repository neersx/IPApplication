import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

@Component({
    selector: 'ipx-debtor-status-icon',
    templateUrl: './ipx-debtor-status-icon.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxdebtorStatusIconComponent  {
    @Input() flagDescription: string;
    @Input() debtorAction: number;
    debtorRestriction: any = KnownDebtorRestrictions;
}

export enum KnownDebtorRestrictions {
    DisplayError = 0,
    DisplayWarning = 1,
    DisplayWarningWithPasswordConfirmation = 2,
    NoRestriction = 3
}