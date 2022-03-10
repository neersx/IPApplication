import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { StateService } from '@uirouter/core';
import { ScreenDesignerCriteriaDetails, ScreenDesignerService } from 'configuration/rules/screen-designer/screen-designer.service';
import { BehaviorSubject, Subject } from 'rxjs';

@Component({
  selector: 'ipx-inheritance-detail',
  templateUrl: './ipx-inheritance-detail.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxInheritanceDetailComponent {

  @Input() set criteriaNo(value: number) {
    if (value) {
      this.onCriteriaChange(value);
    }
  }

  @Input() rowKey?: number;
  readonly $criteriaDetails = new BehaviorSubject<ScreenDesignerCriteriaDetails>(new ScreenDesignerCriteriaDetails());
  constructor(private readonly $state: StateService, private readonly service: ScreenDesignerService) {
  }

  private readonly onCriteriaChange = (value: number) => {
    this.service.getCriteriaDetails$(value).toPromise().then((data) => {
      this.$criteriaDetails.next(data);
    });
  };

  navigateToCriteria = () => {
    const id = this.$criteriaDetails.getValue().id;
    this.service.pushState({ id, stateName: 'screenDesignerCaseInheritance' });
    this.$state.go('screenDesignerCaseCriteria', { id, rowKey: this.rowKey });
  };
}
