import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'grid-toolbar',
    template: '<ng-content></ng-content>',
    changeDetection: ChangeDetectionStrategy.OnPush
  })
export class GridToolbarComponent {
}
