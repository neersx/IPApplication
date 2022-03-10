import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
    selector: 'ipx-topics-header',
    template: '<ng-content></ng-content>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxTopicsHeaderComponent {
}
