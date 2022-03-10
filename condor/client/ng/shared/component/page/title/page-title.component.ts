import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

@Component({
    selector: 'ipx-page-title',
    templateUrl: './page-title.html',
    changeDetection: ChangeDetectionStrategy.OnPush
  })
export class PageTitleComponent {
    @Input() title: string;
    @Input() subtitle: string;
    @Input() subtitleTranlslateValues: string;
    @Input() description: string;
}
