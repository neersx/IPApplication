import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { NamesSummaryPaneService, NameSummaryPaneModel } from 'names/names-summary-pane/names-summary-pane.service';

@Component({
  selector: 'ipx-names-summary-pane',
  templateUrl: './names-summary-pane.component.html',
  styleUrls: ['./names-summary-pane.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class NamesSummaryPaneComponent implements OnInit {
  _nameId: number;
  @Input() showLink: Boolean;
  @Input() set nameId(nameId: number) {
    this._nameId = nameId;
    this.loadDetails();
  }
  nameDetailData: NameSummaryPaneModel;
  constructor(private readonly service: NamesSummaryPaneService, private readonly cdRef: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.loadDetails();
  }

  loadDetails(): void {
    if (this._nameId) {
      this.service.getName(this._nameId).then((name) => {
        this.nameDetailData = name;
        this.cdRef.markForCheck();
      });

      return;
    }
    this.nameDetailData = null;
  }
}
