import { Injectable } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable } from 'rxjs/internal/Observable';
import { HideEvent, IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationComponent } from './ipx-notification.component';
import { IpxNotificationConfig, NotificationType } from './ipx-notification.config';

@Injectable({
  providedIn: 'root'
})
export class IpxNotificationService {
  private modalRef: BsModalRef;

  get onHide$(): Observable<HideEvent> {
    return this.modalService.onHide$;
  }

  constructor(private readonly modalService: IpxModalService) {
  }
  openConfirmationModal(title: string, message: string, confirmText?: string, cancelText?: string, errors?: Array<string>, messageParams?: any, isAnimated?: boolean, withCheckbox?: boolean, checkboxLabel?: string, isByDefaultChecked?: boolean): BsModalRef {
    const config: IpxNotificationConfig = {
      type: NotificationType.confirmOk,
      size: 'md',
      title: title || 'modal.confirmation.title',
      message: message || 'modal.alert.message',
      confirmText: confirmText || 'modal.confirmation.yes',
      cancelText: cancelText || 'modal.confirmation.no',
      errors,
      messageParams,
      animated: isAnimated === undefined ? true : isAnimated,
      showCheckbox: withCheckbox,
      checkboxLabel,
      isChecked: isByDefaultChecked
    };

    return this.openModal(config);
  }

  openAdHocDateMaintenanceModal(): BsModalRef {
    const config: IpxNotificationConfig = {
      type: NotificationType.adhocMaintenance,
      size: 'md',
      title: 'adHocDate.adhocResponsible.title',
      message: 'adHocDate.adhocResponsible.message',
      confirmText: 'adHocDate.adhocResponsible.changeRecipient',
      createCopy: 'adHocDate.adhocResponsible.createCopy',
      cancelText: 'adHocDate.adhocResponsible.cancel'
    };

    return this.openModal(config);
  }

  openPolicingModal(): BsModalRef {
    const config: IpxNotificationConfig = {
      type: NotificationType.policing,
      size: 'xs',
      title: 'caseview.actions.policing',
      message: ''
    };

    return this.openModal(config);
  }

  openDeleteConfirmModal(message: string, messageParams?: any, withCheckbox?: boolean, checkboxLabel?: string): BsModalRef {
    const config: IpxNotificationConfig = {
      type: NotificationType.confirmDelete,
      size: 'md',
      title: 'confirmDeletion',
      message: message || 'dataItem.confirmDelete',
      errors: null,
      confirmText: '',
      messageParams,
      showCheckbox: withCheckbox,
      checkboxLabel
    };

    return this.openModal(config);
  }

  openAlertModal(title: string, message: string, errors?: Array<any>, confirmText?: string, messageParams?: any): BsModalRef {
    const isSingleErrorMessage = (errors && errors.length === 1);
    const config: IpxNotificationConfig = {
      type: NotificationType.alert,
      size: 'lg',
      isAlertWindow: true,
      title: title || 'modal.unableToComplete',
      message: message || (isSingleErrorMessage ? errors[0] : 'modal.alert.message'),
      messageParams,
      errors: isSingleErrorMessage ? null : errors,
      confirmText: confirmText || 'button.ok',
      animated: false
    };

    return this.openModal(config);
  }

  openWarningModal(title: string, message: string, confirmText?: string, messageParams?: any): BsModalRef {
    const config: IpxNotificationConfig = {
      type: NotificationType.alert,
      size: 'lg',
      isWarningWindow: true,
      title: title || 'modal.warning.warning',
      message: message ?? '',
      messageParams,
      confirmText: confirmText || 'button.ok',
      animated: false
    };

    return this.openModal(config);
  }

  openAlertListModal(title: string, message: string, confirmText?: string, cancelText?: string, errors?: Array<string>, messageParams?: any, isAnimated?: boolean, withCheckbox?: boolean, checkboxLabel?: string, isByDefaultChecked?: boolean, isAlertWindow?: boolean, size?: string): BsModalRef {
    const config: IpxNotificationConfig = {
      type: NotificationType.list,
      size: size || 'md',
      isAlertWindow,
      title: title || 'modal.confirmation.title',
      message: message || 'modal.alert.message',
      confirmText: confirmText || 'modal.confirmation.yes',
      cancelText: '',
      errors,
      messageParams,
      animated: true,
      showCheckbox: false
    };

    return this.openModal(config);
  }

  openInfoModal(title: string, message: string, confirmText?: string, errors?: Array<any>, messageParams?: any): BsModalRef {
    const isSingleErrorMessage = (errors && errors.length === 1);
    const config: IpxNotificationConfig = {
      type: NotificationType.Info,
      size: 'lg',
      title: title || 'modal.information',
      message: message || (isSingleErrorMessage ? errors[0] : 'modal.alert.message'),
      messageParams,
      errors: isSingleErrorMessage ? null : errors,
      confirmText: confirmText || 'button.ok',
      animated: false
    };

    return this.openModal(config);
  }

  openSanityModal(title: string, message: string, errors?: Array<any>, warnings?: Array<any>, showIgnore?: boolean, hasErrors?: boolean): BsModalRef {
    const config: IpxNotificationConfig = {
      type: NotificationType.sanityCheck,
      size: 'lg',
      isAlertWindow: hasErrors,
      isWarningWindow: !hasErrors,
      title: title || 'modal.unableToComplete',
      message,
      errors,
      warnings,
      confirmText: showIgnore ? 'sanityChecks.ignoreErrors' : '',
      cancelText: 'sanityChecks.close',
      animated: false
    };

    return this.openModal(config);
  }

  openDiscardModal(): BsModalRef {
    const config: IpxNotificationConfig = {
      type: NotificationType.discard,
      size: 'md',
      title: 'modal.discardchanges.title',
      message: 'modal.discardchanges.discardMessage',
      animated: false
    };

    return this.openModal(config);
  }

  private readonly openModal = (config: IpxNotificationConfig): BsModalRef => {
    let modalClass = 'modal-' + (config.size || 'md');
    if (config.isAlertWindow) {
      modalClass += ' modal-alert';
    }
    if (config.isWarningWindow) {
      modalClass += ' modal-warning';
    }

    const initialState = {
      config
    };

    this.modalRef = this.modalService.openModal(IpxNotificationComponent,
      { animated: config.animated === undefined ? true : config.animated, class: modalClass, ignoreBackdropClick: true, initialState }, true);

    return this.modalRef;
  };
}