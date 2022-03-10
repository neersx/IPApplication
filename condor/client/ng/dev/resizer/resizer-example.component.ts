import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'ngx-resizer',
    templateUrl: './resizer-example.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class ResizerExampleComponent {
}
