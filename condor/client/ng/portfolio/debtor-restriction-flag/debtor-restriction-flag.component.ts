import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { DebtorRestrictionsService, IDebtorRestriction, IDebtorRestrictionsService } from './debtor-restriction.service';

@Component({
    selector: 'ipx-debtor-restriction-flag',
    templateUrl: './debtor-restriction-flag.component.html',
    styleUrls: ['./debtor-restriction-flag.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DebtorRestrictionFlagComponent implements OnInit {
    _debtor;
    @Input() set debtor(value) {
        this._debtor = value;
        this.load();
    }
    severity: string;
    description: string;
    constructor(private readonly service: DebtorRestrictionsService, private readonly cdr: ChangeDetectorRef) { }

    ngOnInit(): void {
        this.load();
    }

    load(): void {
        if (!this._debtor) {
            this.severity = '';
            this.description = '';

            return;
        }

        this.service.getRestrictions(this._debtor)
            .subscribe((r: Array<IDebtorRestriction>) => {
                if (r.length) {
                    this.severity = r[0].severity;
                    this.description = r[0].description;
                } else {
                    this.severity = '';
                    this.description = '';
                }
                this.cdr.detectChanges();
            });
    }
}
