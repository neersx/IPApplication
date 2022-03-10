import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input } from '@angular/core';

@Component({
  selector: 'internal-name-details',
  templateUrl: './internal-name-details.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class InternalNameDetailsComponent {

  @Input() viewData: any;
  constructor(readonly cdref: ChangeDetectorRef) {
  }
}
