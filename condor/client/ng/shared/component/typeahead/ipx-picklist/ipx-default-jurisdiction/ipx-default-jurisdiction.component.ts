import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

@Component({
  selector: 'ipx-default-jurisdiction',
  templateUrl: './ipx-default-jurisdiction.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxDefaultJurisdictionComponent {

  @Input() resultGridData: Array<any>;

  isDefaultJurisdiction = (): boolean => {

    return this.resultGridData && this.resultGridData.length > 0 && this.resultGridData[0].isDefaultJurisdiction && this.resultGridData[0].isDefaultJurisdiction === true;
  };
}
