import { AfterViewInit, ChangeDetectionStrategy, Component, TemplateRef, ViewChild } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { IpxNotificationConfig, NotificationType } from './ipx-notification.config';

@Component({
  selector: 'notification',
  templateUrl: './ipx-notification.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxNotificationComponent implements AfterViewInit {
  @ViewChild('alert') alertTemplate: TemplateRef<any>;
  @ViewChild('alertList') alertListTemplate: TemplateRef<any>;
  @ViewChild('confirmOk') confirmOkTemplate: TemplateRef<any>;
  @ViewChild('confirmDelete') confirmDeleteTemplate: TemplateRef<any>;
  @ViewChild('info') infoTemplate: TemplateRef<any>;
  @ViewChild('discard') discardTemplate: TemplateRef<any>;
  @ViewChild('policing') policingTemplate: TemplateRef<any>;
  @ViewChild('sanityCheck') sanityCheckTemplate: TemplateRef<any>;
  @ViewChild('adhocMaintenance') adhocMaintenanceTemplate: TemplateRef<any>;

  confirmed$ = new Subject<any>();
  cancelled$ = new Subject<string>();
  createCopy$ = new Subject<any>();

  config: IpxNotificationConfig;

  configuredTemplate$ = new Subject();
  id: string;
  showCheckBox: boolean;
  checkboxLabel: string;
  isChecked: boolean;

  private readonly modalRef: BsModalRef;

  constructor(bsModalRef: BsModalRef) {
    this.modalRef = bsModalRef;
  }

  ngAfterViewInit(): void {
    this.switchTemplatesHookup();
    this.showCheckBox = this.config.showCheckbox;
    this.checkboxLabel = this.config.checkboxLabel;
    this.isChecked = this.config.isChecked;
  }

  confirm = () => {
    this.modalRef.hide();
    this.confirmed$.next(this.isChecked ? 'confirmApply' : 'confirm');
  };

  cancel = () => {
    this.modalRef.hide();
    this.cancelled$.next('cancel');
  };

  createCopy = () => {
    this.modalRef.hide();
    this.createCopy$.next(this.isChecked ? 'confirmApply' : 'confirm');
  };

  private readonly switchTemplatesHookup = () => {
    switch (this.config.type) {
      case NotificationType.Info:
        this.id = 'confirmModal';
        this.configuredTemplate$.next(this.infoTemplate);
        break;
      case NotificationType.alert:
        this.id = 'alertModal';
        this.configuredTemplate$.next(this.alertTemplate);
        break;
      case NotificationType.list:
        this.id = 'alertListModal';
        this.configuredTemplate$.next(this.alertListTemplate);
        break;
      case NotificationType.confirmDelete:
        this.id = 'confirmDeleteModal';
        this.configuredTemplate$.next(this.confirmDeleteTemplate);
        break;
      case NotificationType.confirmOk:
        this.id = 'confirmModal';
        this.configuredTemplate$.next(this.confirmOkTemplate);
        break;
      case NotificationType.discard:
        this.id = 'discardChangesModal';
        this.configuredTemplate$.next(this.discardTemplate);
        break;
      case NotificationType.policing:
        this.id = 'policingModal';
        this.configuredTemplate$.next(this.policingTemplate);
        break;
      case NotificationType.sanityCheck:
        this.id = 'sanityCheckModal';
        this.configuredTemplate$.next(this.sanityCheckTemplate);
        break;
      case NotificationType.adhocMaintenance:
        this.id = 'adhocMaintenanceModal';
        this.configuredTemplate$.next(this.adhocMaintenanceTemplate);
        break;
      default:
        this.configuredTemplate$.next(this.infoTemplate);
        break;
    }
  };
}
