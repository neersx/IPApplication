import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { StateService } from '@uirouter/angular';
import { Topic, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import { AttachmentConfigurationService } from '../attachments-configuration.service';

@Component({
  selector: 'app-attachment-dms-integration',
  templateUrl: './attachment-dms-integration.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AttachmentDmsIntegrationComponent implements OnInit {
  @Input() topic: Topic;
  viewData: any;
  isDmsEnabled: boolean;
  enableChanged: boolean;
  constructor(private readonly service: AttachmentConfigurationService, public $state: StateService) { }

  ngOnInit(): void {
    this.viewData = this.topic.params.viewData;
    this.isDmsEnabled = this.viewData.hasDmsSettings ? this.viewData.enableDms !== false : false;
    this.topic.getDataChanges = this.getChanges;
  }
  changeStatus = (value: Event): void => {
    this.topic.hasChanges = this.topic.params.viewData.enableDms !== value;
    this.enableChanged = true;
    this.service.raisePendingChanges(this.topic.hasChanges);
  };

  navigateToDmsConfiguration = (): void => {
    this.$state.go('dmsIntegration', {});
  };

  private readonly getChanges = (): { [key: string]: any } => {
    const data = {
      ['enableDms']: this.topic.hasChanges ? this.isDmsEnabled : this.viewData.enableDms
    };

    return data;
  };
}

export class AttachmentDmsIntegrationTopic extends Topic {
  key = 'attachmentDmsIntegration';
  title = 'attachmentsIntegration.attachmentDmsIntegration.title';
  readonly component = AttachmentDmsIntegrationComponent;
  constructor(public params: any) {
    super();
  }
}
