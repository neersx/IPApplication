import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { CaseHeaderService } from './case-header.service';

@Component({
  selector: 'ipx-case-header',
  templateUrl: './case-header.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseHeaderComponent implements OnInit {
  @Input() caseKey: number;
  header: any;
  constructor(readonly service: CaseHeaderService, readonly cdr: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.service.getHeader(this.caseKey).then(header => {
      this.header = header;
      this.cdr.markForCheck();
    });
  }

}
