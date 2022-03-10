import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

@Component({
  selector: 'ipx-related-cases-other-details',
  templateUrl: './related-cases-other-details.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RelatedCasesOtherDetailsComponent {
  @Input() dataItem: any;
}
