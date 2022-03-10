import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { Topic, TopicViewData } from 'shared/component/topics/ipx-topic.model';
import { AttachmentConfigurationService } from '../attachments-configuration.service';

@Component({
  selector: 'app-attachment-browse-setting',
  templateUrl: './attachment-browse-setting.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AttachmentBrowseSettingComponent implements OnInit {
  @Input() topic: Topic;
  enableBrowseButton: boolean;
  enableChanged: boolean;
  constructor(private readonly service: AttachmentConfigurationService) { }

  ngOnInit(): void {
    this.enableBrowseButton = this.topic.params.viewData.enableBrowseButton;
    this.topic.getDataChanges = this.getChanges;
  }
  changeStatus = (value: Event) => {
    this.topic.hasChanges = this.topic.params.viewData.enableBrowseButton !== value;
    this.enableChanged = true;
    this.service.raisePendingChanges(this.topic.hasChanges);
  };

  private readonly getChanges = (): { [key: string]: any } => {
    const data = {
      ['enableBrowseButton']: this.enableBrowseButton
    };

    return data;
  };
}

export class AttachmentBrowseSettingTopic extends Topic {
  key = 'attachmentBrowseSetting';
  title = 'attachmentsIntegration.attachmentBrowseSetting.title';
  readonly component = AttachmentBrowseSettingComponent;
  constructor(public params: any) {
    super();
  }
}
