import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'before-buttons',
    template: '<ng-content></ng-content>&nbsp;',
    changeDetection: ChangeDetectionStrategy.OnPush
  })
export class BeforeButtonsComponent {
}