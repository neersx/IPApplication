import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';

@Component({
  selector: 'ipx-picklist',
  templateUrl: './ipx-picklist.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxPicklistE2eComponent implements OnInit {
  formResult = '';
  numberType: any;
  propertyType: any;
  jurisdiction: any;
  caseType: any;
  group: any;
  model = [];
  // tslint:disable-next-line: no-empty
  ngOnInit(): void {
  }

  setTableType = (query) => {
    const extended = { ...query, tableType: 'eventgroup' };

    return extended;
  };

  onSubmit = () => {
    this.formResult = 'PASS';
  };
}
