import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'after-title',
    template: '&nbsp;<ng-content></ng-content>',
    changeDetection: ChangeDetectionStrategy.OnPush
  })
export class AfterTitleComponent {
}
