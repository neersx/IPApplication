import { ChangeDetectionStrategy, Component, Input, OnChanges, SimpleChanges } from '@angular/core';
import { EmailTemplate } from './email-template';

@Component({
  selector: 'ipx-email-link',
  templateUrl: './ipx-email-link.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxEmailLinkComponent implements OnChanges {
  @Input() model: EmailTemplate;
  email: string;
  @Input() text: string;
  @Input() showIcon: boolean;

  ngOnChanges(changed: SimpleChanges): void {
      const m = changed.model;
      if (m && m.currentValue && !this.email) {
          this.email = this.createUri(this.model);
      }
  }

  isValid = (): boolean => {
    return this.email != null;
  };

  createUri = (emailTemplate: EmailTemplate): string => {
    const link = [];
    if (emailTemplate.recipientCopiesTo && emailTemplate.recipientCopiesTo.length > 0) {
        link.push(`cc=${emailTemplate.recipientCopiesTo.join(';')}`);
    }
    if (emailTemplate.subject) {
        link.push(`subject=${encodeURIComponent(emailTemplate.subject)}`);
    }
    if (emailTemplate.body) {
        link.push(`body=${encodeURIComponent(emailTemplate.body)}`);
    }

    return `${'mailto:' + emailTemplate.recipientEmail}?${link.join('&')}`;
  };
}
