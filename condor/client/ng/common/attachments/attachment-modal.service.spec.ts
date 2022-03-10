import { HttpClientMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { AttachmentMaintenanceComponent } from './attachment-maintenance/attachment-maintenance.component';
import { AttachmentModalService } from './attachment-modal.service';
import { AttachmentServiceMock } from './attachment.service.mock';
import { AttachmentsModalComponent } from './attachments-modal/attachments-modal.component';

describe('Service: AttachmentModal', () => {
  let http: HttpClientMock;
  let modalService: ModalServiceMock;
  let attachmentService: AttachmentServiceMock;

  let service: AttachmentModalService;

  beforeEach(() => {
    http = new HttpClientMock() as any;
    modalService = new ModalServiceMock() as any;
    attachmentService = new AttachmentServiceMock() as any;
    service = new AttachmentModalService(http as any, modalService as any, attachmentService as any);

    service.attachmentsModified = { emit: jest.fn() } as any;
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  it('displays attachment modal', () => {
    const eventDetails = { eventKey: 11, eventCycle: 1, actionKey: 'A' };
    modalService.openModal.mockReturnValue({ content: { dataModified$: of(true) } });
    service.displayAttachmentModal('case', 10, eventDetails);

    expect(modalService.openModal).toHaveBeenCalled();
    expect(modalService.openModal.mock.calls[0][0]).toBe(AttachmentsModalComponent);
    expect(modalService.openModal.mock.calls[0][1].initialState.baseType).toBe('case');
    expect(modalService.openModal.mock.calls[0][1].initialState.key).toBe(10);
    expect(modalService.openModal.mock.calls[0][1].initialState.eventDetails).toBe(eventDetails);

    service.displayAttachmentModal('priorArt', 999111, null, 'priorArtHeader - boop boop');
    expect(modalService.openModal.mock.calls[1][1].initialState.baseType).toBe('priorArt');
    expect(modalService.openModal.mock.calls[1][1].initialState.key).toBe(999111);
    expect(modalService.openModal.mock.calls[1][1].initialState.headerData).toBe('priorArtHeader - boop boop');
  });

  it('emits attachmentsModified, if data modified while displaying attachment', () => {
    modalService.openModal.mockReturnValue({ content: { dataModified$: of(true) } });

    service.displayAttachmentModal('case', 10, {});
    expect(service.attachmentsModified.emit).toHaveBeenCalledWith(true);
  });

  it('emits attachmentsModified, if data modified while displaying attachment', () => {
    modalService.openModal.mockReturnValue({ content: { dataModified$: of(false) } });

    service.displayAttachmentModal('case', 10, {});
    expect(service.attachmentsModified.emit).not.toHaveBeenCalled();
  });

  it('displays add attachment modal', () => {
    attachmentService.attachmentMaintenanceView$.mockReturnValue(of({ a: 'somedata', activityDetails: { b: 'some other data' } }));

    const eventDetails = { eventKey: 11, eventCycle: 1, actionKey: 'A' };
    modalService.openModal.mockReturnValue({ content: { dataModified$: of(true) } });

    service.triggerAddAttachment('case', 10, eventDetails);

    expect(modalService.openModal).toHaveBeenCalled();
    expect(modalService.openModal.mock.calls[0][0]).toBe(AttachmentMaintenanceComponent);
    expect(modalService.openModal.mock.calls[0][1].initialState.viewData.baseType).toBe('case');
    expect(modalService.openModal.mock.calls[0][1].initialState.viewData.id).toBe(10);
    expect(modalService.openModal.mock.calls[0][1].initialState.viewData.actionKey).toBe('A');
    expect(modalService.openModal.mock.calls[0][1].initialState.viewData.a).toBe('somedata');
    expect(modalService.openModal.mock.calls[0][1].initialState.activityDetails).toEqual({ b: 'some other data' });
  });

  it('emits attachmentsModified, if data modified while adding attachment', () => {
    attachmentService.attachmentMaintenanceView$.mockReturnValue(of({}));
    modalService.openModal.mockReturnValue({ content: { onClose$: of(true) } });

    service.triggerAddAttachment('case', 10, {});
    expect(service.attachmentsModified.emit).toHaveBeenCalledWith(true);
  });

  it('emits attachmentsModified, if data modified while adding attachment', () => {
    attachmentService.attachmentMaintenanceView$.mockReturnValue(of({}));
    modalService.openModal.mockReturnValue({ content: { onClose$: of(false) } });

    service.triggerAddAttachment('case', 10, {});
    expect(service.attachmentsModified.emit).not.toHaveBeenCalled();
  });
});
