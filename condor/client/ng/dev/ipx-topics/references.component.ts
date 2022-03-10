import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { Topic, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';

@Component({
  selector: 'ipx-Dev-Topics-References',
  templateUrl: './references.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ReferencesComponent implements OnInit {
  topic: Topic;
  formData: any;

  ngOnInit(): any {
    _.extend(this.topic, {
      isEmpty: this.isEmpty,
      isActive: false
    });
    this.formData = {};
  }

  hasError = (): boolean => {
    return true;
  };

  isEmpty = (): boolean => {
    return false;
  };

  discard(): void {
    throw new Error('Method not implemented.');
  }

  getFilterCriteria(): any {
    // create filter criteria/data from form data
    return this.formData;
  }
}
