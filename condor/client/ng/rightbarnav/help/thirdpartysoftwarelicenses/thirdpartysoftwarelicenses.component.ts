import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { BsModalService } from 'ngx-bootstrap/modal';

@Component({
  selector: 'app-thirdpartysoftwarelicenses',
  templateUrl: './thirdpartysoftwarelicenses.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThirdPartySoftwareLicensesComponent implements OnInit {

  lines: any;
  credits: any;
  constructor(readonly modalService: BsModalService, private readonly cdref: ChangeDetectorRef) { }

  ngOnInit(): void {

    this.lines = this.credits.map(i => {
      const t = i.split(' [');
      if (t.length === 2) {
        return {
          oss: t[0],
          link: t[1].replace(']', '')
        };
      }

      return { oss: i };
    });
    this.cdref.detectChanges();
  }

  close = () => {
    this.modalService.hide(1);
  };

  trackByFn = (index: number, item: any) => {
    return index;
  };

}
