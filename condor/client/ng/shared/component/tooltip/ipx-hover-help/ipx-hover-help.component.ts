import { ChangeDetectionStrategy, Component, ElementRef, Input } from '@angular/core';
@Component({
  selector: 'ipx-hover-help',
  templateUrl: './ipx-hover-help.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxHoverHelpComponent {
   @Input() content: string;
   @Input() placement: string;
   @Input() title: string;
   @Input() container: string;
   get hasData(): boolean {
      return !!this.content || !!this.title;
   }
}