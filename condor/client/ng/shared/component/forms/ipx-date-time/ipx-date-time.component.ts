import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

@Component({
  selector: 'ipx-date-time',
  templateUrl: './ipx-date-time.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxDateTimeComponent {
  @Input() model: Date;
  @Input() timeFormat: string;

}
