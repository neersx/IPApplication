import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';

@Component({
  selector: 'ipx-text-area',
  templateUrl: './ipx-textarea.component.html',
  styleUrls: ['./ipx-textarea.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxTextareaComponent {
  @Input() content: string;
}
