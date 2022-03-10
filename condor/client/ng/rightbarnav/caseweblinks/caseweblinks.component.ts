import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input } from '@angular/core';

@Component({
  selector: 'app-caseWebLinks',
  templateUrl: './caseWebLinks.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseWebLinksComponent {

  @Input() viewData: any;
  constructor(readonly cdref: ChangeDetectorRef) {

  }
  hasCaseLinks = () => {
    return this.viewData && this.viewData.length > 0;
  };

  trackByFn = (index: number, item: any) => {
    return index;
  };
}
