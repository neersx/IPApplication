import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ChangeDetectorRefMock } from 'mocks';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { of } from 'rxjs';
import { AttachmentServiceMock } from '../../attachments/attachment.service.mock';
import { GenerateDocumentErrorsComponent } from './generate-document-errors/generate-document-errors.component';
import { GenerateDocumentComponent } from './generate-document.component';
import { GenerateDocumentServiceMock } from './generate-document.service.mock';

describe('GenerateDocumentComponent', () => {
  let component: GenerateDocumentComponent;
  let service: GenerateDocumentServiceMock;
  let modalRef: any;
  let attachmentService: AttachmentServiceMock;
  let messagingService: WindowParentMessagingServiceMock;
  let appContextService: AppContextServiceMock;
  let modalService: { openModal: jest.Mock };
  let cdr: any;
  let rootScope: any;
  beforeEach(() => {
    modalRef = {
      hide: jest.fn()
    };
    service = new GenerateDocumentServiceMock();
    attachmentService = new AttachmentServiceMock();
    cdr = new ChangeDetectorRefMock();
    messagingService = new WindowParentMessagingServiceMock();
    appContextService = new AppContextServiceMock();
    rootScope = {};
    modalService = { openModal: jest.fn() };
    component = new GenerateDocumentComponent(modalRef, service as any, attachmentService as any, cdr, messagingService as any, rootScope, appContextService as any, modalService as any);
    component.maintenanceForm = { save: jest.fn(), formGroup: { value: { filePath: 'c:', fileName: 'b.doc' } } } as any;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should update status', () => {
    component.updateStatus(false);
    expect(component.hasValidChanges$.getValue()).toBeFalsy();
  });

  it('should update document', () => {
    component.documentAttachmentsDisabled = false;
    component.document = { key: 123, addAttachment: true };
    component.onDocumentChange();
    expect(component.addAsAttachment).toBeTruthy();
    expect(component.documentId$.getValue()).toEqual(123);
  });

  describe('Generate', () => {
    it('should not generate without document selected', () => {
      component.generateAndSave();

      expect(service.getDataForAdhocDoc$).not.toHaveBeenCalled();
    });

    it('should default add as attachment to false', () => {
      component.document = { key: 1 };
      component.caseKey = 123;
      component.isCase = true;
      component.generateAndSave();

      expect(service.getDataForAdhocDoc$).toHaveBeenCalledWith('CaseView', 123, 1, false);
    });

    it('should call generate pdf correctly', () => {
      component.document = { key: 1, template: 'template.pdf', value: 'name' };
      component.caseKey = 123;
      component.isCase = true;
      component.irn = 'abc';
      component.isWord = false;
      component.addAsAttachment = true;
      service.generateAndSavePdf$ = jest.fn().mockReturnValue(of({ isSuccess: true, fileIdentifier: 'yyy-aaa-ccc' }));
      component.generateAndSave();

      expect(service.getDataForAdhocDoc$).toHaveBeenCalledWith('CaseView', 123, 1, true);
      expect(service.generateAndSavePdf$).toHaveBeenCalledWith('CaseView', 123, 1, 'name', 'template.pdf', 'c:', 'b.doc', 'abc');
    });

    it('should show pdf error modal if any errors', () => {
      component.document = { key: 1, template: 'template.pdf', value: 'name' };
      component.caseKey = 123;
      component.isCase = true;
      component.irn = 'abc';
      component.isWord = false;
      component.addAsAttachment = true;
      service.generateAndSavePdf$ = jest.fn().mockReturnValue(of({ isSuccess: true, fileIdentifier: 'yyy-aaa-ccc', errors: [{ error: 'failure' }] }));
      component.generateAndSave();

      expect(modalService.openModal).toHaveBeenCalledWith(GenerateDocumentErrorsComponent, expect.objectContaining({}));
    });

    it('should not get generated pdf', () => {
      component.document = { key: 1, template: 'template.pdf', value: 'name' };
      component.caseKey = 123;
      component.isCase = true;
      component.irn = 'abc';
      component.isWord = false;
      component.addAsAttachment = true;
      service.generateAndSavePdf$ = jest.fn().mockReturnValue(of({ isSuccess: false, fileIdentifier: '' }));
      component.generateAndSave();

      expect(service.getDataForAdhocDoc$).toHaveBeenCalledWith('CaseView', 123, 1, true);
      expect(service.generateAndSavePdf$).toHaveBeenCalledWith('CaseView', 123, 1, 'name', 'template.pdf', 'c:', 'b.doc', 'abc');
    });

    it('should pass add as attachment to false', () => {
      component.document = { key: 1 };
      component.addAsAttachment = true;
      component.nameKey = 123;
      component.generateAndSave();

      expect(service.getDataForAdhocDoc$).toHaveBeenCalledWith('NameView', 123, 1, true);
    });

    it('should call save', () => {
      component.document = { key: 1 };
      component.addAsAttachment = true;
      component.nameKey = 123;
      component.isWord = true;
      component.hasValidChanges$.next(true);
      service.getDataForAdhocDoc$ = jest.fn().mockReturnValue(of(true));
      component.generateAndSave();

      expect(service.getDataForAdhocDoc$).toHaveBeenCalledWith('NameView', 123, 1, true);
    });
  });

  describe('onClose', () => {
    it('should call the hide method on the modalref', () => {
      component.onClose();

      expect(messagingService.postLifeCycleMessage).toHaveBeenCalled();
    });
  });

  describe('onInit', () => {
    it('should set translation prefix correctly if isWord is true', () => {
      component.isWord = true;
      (attachmentService as any).attachmentMaintenanceView$.mockReturnValue({ subscribe: jest.fn() });
      component.ngOnInit();

      expect(component.translationPrefix).toEqual('documentGeneration.generateWord.');
    });

    it('should set translation prefix correctly if isWord is false', () => {
      component.isWord = false;
      (attachmentService as any).attachmentMaintenanceView$.mockReturnValue({ subscribe: jest.fn() });
      component.ngOnInit();

      expect(component.translationPrefix).toEqual('documentGeneration.generatePdf.');
    });
  });
});
