import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'ipx-tooltip-dev',
  templateUrl: './inline-dialog-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class InlineDialogExampleComponent {
  html = ' <span class="btn btn-danger">Hello World</span>';
}
