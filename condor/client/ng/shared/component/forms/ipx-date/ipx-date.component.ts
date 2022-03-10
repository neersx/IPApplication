import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

@Component({
  selector: 'ipx-date',
  templateUrl: './ipx-date.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxDateComponent {
  @Input() model: Date;

}
