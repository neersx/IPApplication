import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';

@Component({
  selector: 'ipx-Dev-Topics-Characteristics',
  templateUrl: './characteristics.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CharacteristicsComponent implements OnInit {
  topic: Topic;
  formData: any = {};

  ngOnInit(): void {
    _.extend(this.topic, {
      isEmpty: this.isEmpty,
      hasError: this.hasError,
      isActive: true,
      formData: this.formData
    });
  }

  isEmpty = (): boolean => {
    return false;
  };

  getTopicCount = (): number => {
    return 10;
  };

  hasError = (): boolean => {
    return false;
  };
}
