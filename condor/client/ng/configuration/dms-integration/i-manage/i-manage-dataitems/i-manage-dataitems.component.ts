import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { DmsIntegrationService } from 'configuration/dms-integration/dms-integration.service';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';

@Component({
  selector: 'i-manage-dataitems',
  templateUrl: './i-manage-dataitems.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IManageDataItemsComponent implements OnInit {
  @ViewChild('dataItemForm', { static: true }) form: NgForm;
  caseSearch: any;
  nameSearch: any;
  isTestCaseDocumentDisabled = false;
  @Input() topic: Topic;
  constructor(private readonly dmsService: DmsIntegrationService, private readonly modalService: IpxModalService) {

  }

  ngOnInit(): void {
    this.topic.getDataChanges = this.getChanges;
    const dataItems = this.topic.params.viewData && this.topic.params.viewData.imanageSettings ? this.topic.params.viewData.imanageSettings.dataItems : {};
    if (dataItems) {
      this.caseSearch = dataItems.caseSearch;
      this.nameSearch = dataItems.nameSearch;
    }
    this.subscribeFormEvents();
  }

  private readonly subscribeFormEvents = () => {
    this.form.statusChanges.subscribe(c => {
      this.topic.hasChanges = this.form.dirty;
      this.topic.setErrors(this.form.invalid);
      this.dmsService.raisePendingChanges(this.topic.hasChanges);
      this.dmsService.raiseHasErrors(this.form.invalid);
    });
  };

  private readonly getChanges = (): { [key: string]: any } => {
    const obj = {
      dataItems: {
        caseSearch: this.caseSearch,
        nameSearch: this.nameSearch
      }
    };

    return obj;
  };
}
