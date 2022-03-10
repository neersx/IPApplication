import { async } from '@angular/core/testing';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { NotificationType } from './ipx-notification.config';
import { IpxNotificationService } from './ipx-notification.service';

describe('NotificationComponent', () => {
  let component: IpxNotificationService;
  let modalServiceMock: ModalServiceMock;
  beforeEach(async(() => {
    modalServiceMock = new ModalServiceMock();
    component = new IpxNotificationService(modalServiceMock as any);
  }));

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('openConfirmationModal', () => {
    it('should call to show the modal with the correct values 4', () => {
      component.openConfirmationModal('testTitle', 'testMessage', 'testConfirmText', 'testCancelText', ['testErrors'], 'testMessageParams');
      const expectedConfig = {
        type: NotificationType.confirmOk,
        size: 'md',
        title: 'testTitle',
        message: 'testMessage',
        confirmText: 'testConfirmText',
        cancelText: 'testCancelText',
        errors: ['testErrors'],
        messageParams: 'testMessageParams'
      };

      expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        animated: true, class: 'modal-' + (expectedConfig.size || 'md'), ignoreBackdropClick: true, initialState: expect.objectContaining({ config: expect.objectContaining(expectedConfig) })
      }), true);
    });
  });

  describe('openDeleteConfirmModal', () => {
    it('should call to show the modal with the correct values 1', () => {
      component.openDeleteConfirmModal('testMessage', 'testMessageParams');
      const expectedConfig = {
        type: NotificationType.confirmDelete,
        size: 'md',
        title: 'confirmDeletion',
        message: 'testMessage',
        confirmText: '',
        messageParams: 'testMessageParams'
      };

      expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        animated: true,
        class: 'modal-md',
        ignoreBackdropClick: true,
        initialState: {
          config: {
            confirmText: '',
            errors: null,
            message: 'testMessage',
            messageParams: 'testMessageParams',
            size: 'md',
            title: 'confirmDeletion',
            type: 2
          }
        }
      }), true);
    });
  });

  describe('openAlertModal', () => {
    it('should call to show the modal with the correct values 2', () => {
      component.openAlertModal('testTitle', 'testMessage', ['testErrors', 'testErrors2'], 'testConfirmText', 'testMessageParams');
      const expectedConfig = {
        type: NotificationType.alert,
        size: 'lg',
        title: 'testTitle',
        message: 'testMessage',
        confirmText: 'testConfirmText',
        errors: ['testErrors', 'testErrors2'],
        messageParams: 'testMessageParams',
        isAlertWindow: true,
        animated: false
      };

      expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        animated: false,
        class: 'modal-lg modal-alert',
        ignoreBackdropClick: true,
        initialState: {
          config: {
            animated: false,
            confirmText: 'testConfirmText',
            errors: [
              'testErrors',
              'testErrors2'
            ],
            isAlertWindow: true,
            message: 'testMessage',
            messageParams: 'testMessageParams',
            size: 'lg',
            title: 'testTitle',
            type: 3
          }
        }
      }), true);
    });

    it('should call to show the first error as message if no message supplied and one error', () => {
      component.openAlertModal('testTitle', '', ['testErrors'], 'testConfirmText', 'testMessageParams');
      const expectedConfig = {
        type: NotificationType.alert,
        size: 'lg',
        title: 'testTitle',
        message: 'testErrors',
        confirmText: 'testConfirmText',
        errors: null,
        messageParams: 'testMessageParams',
        isAlertWindow: true,
        animated: false
      };

      expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        animated: false, class: 'modal-' + (expectedConfig.size || 'md') + ' modal-alert', ignoreBackdropClick: true, initialState: expect.objectContaining({ config: expect.objectContaining(expectedConfig) })
      }), true);
    });
  });
  describe('openDiscardModal', () => {
    it('should call to show the modal with the correct values 3', () => {
      component.openDiscardModal();
      const expectedConfig = {
        type: NotificationType.discard,
        size: 'md',
        title: 'modal.discardchanges.title',
        message: 'modal.discardchanges.discardMessage',
        animated: false
      };

      expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        animated: false, class: 'modal-' + (expectedConfig.size || 'md'), ignoreBackdropClick: true, initialState: expect.objectContaining({ config: expect.objectContaining(expectedConfig) })
      }), true);
    });
  });

  describe('openSanityCheckModal', () => {
    it('should call to show the modal with the correct values', () => {
      component.openSanityModal('testTitle', 'testMessage', ['testErrors', 'testErrors2'], ['testwarning'], false, true);
      const expectedConfig = {
        type: NotificationType.sanityCheck,
        size: 'lg',
        title: 'testTitle',
        message: 'testMessage',
        cancelText: 'sanityChecks.close',
        confirmText: '',
        errors: ['testErrors', 'testErrors2'],
        warnings: ['testwarning'],
        isAlertWindow: true,
        isWarningWindow: false,
        animated: false
      };

      expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        animated: false, class: 'modal-' + (expectedConfig.size || 'md') + ' modal-alert', ignoreBackdropClick: true, initialState: expect.objectContaining({ config: expect.objectContaining(expectedConfig) })
      }), true);
    });

    it('should call to warning window with correc values', () => {
      component.openSanityModal('testTitle', 'testMessage', ['testErrors', 'testErrors2'], ['testwarning'], false, false);
      const expectedConfig = {
        type: NotificationType.sanityCheck,
        size: 'lg',
        title: 'testTitle',
        message: 'testMessage',
        cancelText: 'sanityChecks.close',
        confirmText: '',
        errors: ['testErrors', 'testErrors2'],
        warnings: ['testwarning'],
        isAlertWindow: false,
        isWarningWindow: true,
        animated: false
      };
      expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        animated: false, class: 'modal-' + (expectedConfig.size || 'md') + ' modal-warning', ignoreBackdropClick: true, initialState: expect.objectContaining({ config: expect.objectContaining(expectedConfig) })
      }), true);
    });
  });

  describe('openInfoModal', () => {
    it('should call to show the modal with the correct values 2', () => {
      component.openInfoModal('testTitle', 'testMessage');
      const expectedConfig = {
        type: NotificationType.Info,
        size: 'lg',
        title: 'testTitle',
        message: 'testMessage',
        isAlertWindow: false,
        animated: false
      };

      expect(modalServiceMock.openModal).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        animated: false,
        class: 'modal-lg',
        ignoreBackdropClick: true,
        initialState: {
          config: {
            animated: false,
            confirmText: 'button.ok',
            errors: undefined,
            message: 'testMessage',
            messageParams: undefined,
            size: 'lg',
            title: 'testTitle',
            type: 0
          }
        }
      }), true);
    });
  });
});
