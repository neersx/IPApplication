import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { NameHeaderService } from './name-header.service';

@Component({
  selector: 'ipx-name-header',
  templateUrl: './name-header.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class NameHeaderComponent implements OnInit {
  @Input() nameKey: number;
  header: any;

  constructor(readonly service: NameHeaderService, readonly cdr: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.service.getHeader(this.nameKey).then(header => {
      this.header = header;
      this.cdr.markForCheck();
    });
  }

}
