import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'before-title',
    template: '<ng-content></ng-content>&nbsp;',
    changeDetection: ChangeDetectionStrategy.OnPush
  })
export class BeforeTitleComponent {
}
