import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'topic-group-details',
  template: '<ng-content></ng-content>&nbsp;',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TopicGroupDetailsComponent {
}