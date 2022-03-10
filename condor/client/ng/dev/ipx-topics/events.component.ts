import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';

@Component({
  selector: 'ipx-Dev-Topics-Events',
  templateUrl: './events.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EventsComponent implements OnInit {
  topic: Topic;
  formData: any = {};

  ngOnInit(): any {
    _.extend(this.topic, {
      isEmpty: this.isEmpty,
      hasError: this.hasError,
      isActive: false
    });
  }

  isEmpty = (): boolean => {
    return true;
  };

  hasError = (): boolean => {
    return false;
  };
}
