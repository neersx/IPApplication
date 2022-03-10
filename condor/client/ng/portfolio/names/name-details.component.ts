import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { EmailTemplate } from 'shared/component/forms/ipx-email-link/email-template';
import { DisplayableNameTypeFieldsHelper } from './displayable-fields';
import { NameDetailsService } from './name-details.service';

@Component({
    selector: 'ipx-names-detail',
    templateUrl: './name-details.component.html',
    styleUrls: ['./name-details.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class NameDetailsComponent implements OnInit {
    @Input() details;
    @Input() caseId;
    email: EmailTemplate;

    constructor(private readonly displayableFields: DisplayableNameTypeFieldsHelper, private readonly service: NameDetailsService, private readonly cdr: ChangeDetectorRef) { }

    ngOnInit(): void {
        if (this.details.email) {
            this.service.getFirstEmailTemplate(this.caseId, this.details.typeId, this.details.sequence)
                .subscribe((emailTemplate: EmailTemplate) => {
                    this.email = {
                        recipientEmail: this.details.email,
                        recipientCopiesTo: emailTemplate[0].recipientCopiesTo,
                        subject: emailTemplate[0].subject,
                        body: emailTemplate[0].body
                    };
                    this.cdr.detectChanges();
                });
        }
    }

    show = (flagName: string): boolean => {
        const f = this.displayableFields.mapFlag(flagName);

        return this.displayableFields.shouldDisplay(this.details.displayFlags, [f]);
    };
}