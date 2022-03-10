import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input } from '@angular/core';

@Component({
  selector: 'internal-case-details',
  templateUrl: './internal-case-details.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class InternalCaseDetailsComponent {

  @Input() viewData: any;
  constructor(readonly cdref: ChangeDetectorRef) {
  }
}
