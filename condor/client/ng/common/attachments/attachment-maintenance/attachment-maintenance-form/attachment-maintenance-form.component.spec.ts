import { fakeAsync, flush, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { ChangeDetectorRefMock, DateHelperMock, IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import * as _ from 'underscore';
import { AttachmentServiceMock } from '../../attachment.service.mock';
import { AttachmentMaintenanceFormComponent } from './attachment-maintenance-form.component';

describe('AttachmentMaintenanceFormComponent', () => {
  let component: AttachmentMaintenanceFormComponent;
  let service: AttachmentServiceMock;
  let formBuilder: FormBuilder;
  let messageService: WindowParentMessagingServiceMock;
  let translateService: TranslateServiceMock;
  let dateHelper: DateHelperMock;
  let cdr: any;
  let ipxNotificationService: IpxNotificationServiceMock;
  let notificationService: any;
  let $destroy: any;
  let modal: ModalServiceMock;
  let translate: any;

  const sampleData = {
    activityId: 1001,
    sequenceNo: 0,
    attachmentName: 'testName',
    isPublic: true,
    filePath: 'c:\\abc.pdf',
    eventId: 10,
    eventDescription: 'ABCD',
    eventCycle: 1,
    eventIsCyclic: false,
    activityType: 10,
    activityCategoryId: 12,
    activityDate: '',
    attachmentType: null,
    language: 1,
    languageDescription: 'Mars',
    pageCount: '',
    attachmentDescription: 'this is the attachment',
    isCaseEvent: false
  };

  beforeEach(() => {
    formBuilder = new FormBuilder();
    service = new AttachmentServiceMock();
    messageService = new WindowParentMessagingServiceMock();
    translateService = new TranslateServiceMock();
    dateHelper = new DateHelperMock();
    cdr = new ChangeDetectorRefMock();
    ipxNotificationService = new IpxNotificationServiceMock();
    notificationService = new NotificationServiceMock();
    modal = new ModalServiceMock();
    $destroy = of();
    translate = new TranslateServiceMock();

    component = new AttachmentMaintenanceFormComponent(service as any, formBuilder as any, messageService as any, translateService as any, dateHelper as any, cdr, ipxNotificationService as any, notificationService, modal as any, $destroy, translate, { isHosted: true } as any);
    component.viewData = {};
  });

  it('should create', () => {
    expect(component).toBeTruthy();
    expect(component.eventsFor).toBeDefined();
  });

  it('should create with blank data', () => {
    component.ngOnInit();
    expect(translateService.instant).toHaveBeenCalledWith('attachmentsIntegration.discardMessage');
    expect(component.data).toBeDefined();
    expect(component.formGroup).toBeDefined();
    expect(component.initialValues).toBeDefined();
    expect(component.changeSubscription).toBeDefined();
  });

  it('should create with given data attachment maintenance', () => {
    component.ngOnInit();
    expect(component.data.activityId).toBeNull();
    expect(component.data.language).toBeNull();

    component.activityAttachment = sampleData;
    component.viewData = { baseType: 'case', id: 1, hasAttachmentSettings: true };
    expect(component.data).toEqual(sampleData);
    expect(component.baseType).toEqual('case');
    expect(component.hasSettings).toEqual(true);
    expect(component.isAdding).toEqual(false);
    expect(component.hostTarget).toEqual('attachmentMaintenanceHost');

    expect(component.formGroup.controls.attachmentName.value).toEqual(sampleData.attachmentName);
    expect(component.formGroup.controls.allowClientAccess.value).toEqual(sampleData.isPublic);
    expect(component.formGroup.controls.filePath.value).toEqual(sampleData.filePath);
    expect(component.formGroup.controls.event.value).toEqual({ key: 10, value: 'ABCD' });
    expect(component.formGroup.controls.eventCycle.value).toEqual(sampleData.eventCycle);
    expect(component.formGroup.controls.activityType.value).toEqual(sampleData.activityType);
    expect(component.formGroup.controls.activityCategory.value).toEqual(sampleData.activityCategoryId);
    expect(component.formGroup.controls.activityDate.value).toEqual(null);
    expect(component.formGroup.controls.attachmentType.value).toEqual({});
    expect(component.formGroup.controls.language.value).toEqual({ key: 1, value: 'Mars' });
    expect(component.formGroup.controls.pageCount.value).toEqual(sampleData.pageCount);
  });

  it('should create with given data adHoc generation', () => {
    component.ngOnInit();
    expect(component.data.activityId).toBeNull();
    expect(component.data.language).toBeNull();
    component.viewData = { baseType: 'name', id: 1, hasAttachmentSettings: true, isAdHocGeneration: true };
    expect(component.baseType).toEqual('name');
    expect(component.hasSettings).toEqual(true);
    expect(component.isAdding).toEqual(true);
    expect(component.hostTarget).toEqual('generateDocument');

    expect(component.formGroup.controls.filePath).not.toBeNull();
    expect(component.formGroup.controls.fileName).not.toBeNull();

  });

  it('should create with disabled controls for case attachments', fakeAsync(() => {
    component.ngOnInit();
    component.activityAttachment = sampleData;
    component.disabled = true;
    component.viewData = { baseType: 'case', id: 1 };
    expect(component.data).toEqual(sampleData);
    const controls = ['attachmentName', 'allowClientAccess', 'filePath', 'event', 'eventCycle', 'activityType', 'activityCategory', 'activityDate', 'attachmentType', 'language', 'pageCount'];
    expect(_.every(controls, (controlName) => {
      return component.formGroup.contains(controlName);
    })).toBeFalsy();

    component.disabled = false;
    tick(200);

    expect(_.every(controls, (controlName) => {
      return component.formGroup.contains(controlName);
    })).toBeTruthy();
  }));

  it('should create controls for prior art attachments', fakeAsync(() => {
    component.ngOnInit();
    component.activityAttachment = sampleData;
    component.viewData = { baseType: 'priorArt', id: 999, canBrowseDms: true, caseId: null };
    expect(component.data).toEqual(sampleData);
    expect(component.canBrowseDms).toEqual(false);
    const controls = ['attachmentName', 'attachmentDescription', 'allowClientAccess', 'filePath', 'fileName', 'activityType', 'activityCategory', 'activityDate', 'attachmentType', 'pageCount', 'language'];
    const hiddenControls = ['event', 'eventCycle'];
    expect(_.every(controls, (controlName) => {
      return component.formGroup.contains(controlName);
    })).toBeTruthy();
    expect(_.every(hiddenControls, (controlName) => {
      return component.formGroup.contains(controlName);
    })).toBeFalsy();
  }));

  it('should populate values', () => {
    component.activityAttachment = sampleData;
    component.viewData = { baseType: 'case', id: 1234, defaultFileName: 'attach.doc' };
    component.ngOnInit();

    service.getDeliveryDestination$ = jest.fn().mockReturnValue(of({ directoryName: 'a:\\', fileName: '' }));
    service.getActivity$ = jest.fn().mockReturnValue(of({ activityType: 12, activityCategory: 123 }));
    component.document = 123;

    expect(component.documentSettings).toEqual({
      activityCategory: 123, activityType: 12, fileName: 'attach.doc', filePath: 'a:\\'
    });
  });

  it('should set error on event, if event does not exists on case any more', () => {
    component.activityAttachment = sampleData;
    component.viewData = { baseType: 'case', id: 1, defaultFileName: 'attach.doc' };
    component.ngOnInit();

    const eventSetErrors = jest.spyOn(component.formGroup.controls.event, 'setErrors');
    const eventmarkAsDirty = jest.spyOn(component.formGroup.controls.event, 'markAsDirty');
    component.ngAfterViewInit();

    expect(eventSetErrors).toHaveBeenCalledWith({ 'attachmentMaintenance.eventNotFound': true });
    expect(eventmarkAsDirty).toHaveBeenCalled();
  });

  it('should revert properly', () => {
    component.activityAttachment = sampleData;
    component.viewData = { baseType: 'case', id: 1, defaultFileName: 'attach.doc' };
    component.ngOnInit();
    component.formGroup.controls.attachmentName.setValue('new Value');
    component.formGroup.controls.attachmentName.markAsDirty();
    component.revert();
    expect(component.formGroup.controls.attachmentName.value).toEqual(sampleData.attachmentName);
    expect(component.formGroup.controls.eventCycle.value).toEqual(sampleData.eventCycle);
  });

  it('should save with calls to validate path', () => {
    component.activityAttachment = sampleData;
    component.viewData = { baseType: 'case', id: 1234, defaultFileName: 'attach.doc' };
    component.ngOnInit();
    component.formGroup.controls.filePath.setValue('Q:\\test.pdf');
    component.formGroup.controls.filePath.markAsDirty();
    service.validatePath$ = jest.fn().mockReturnValue(of(true));
    service.addOrUpdateAttachment$ = jest.fn().mockReturnValue(of({}));
    component.save();
    expect(service.validatePath$).toHaveBeenCalledWith('Q:\\test.pdf');
    expect(service.addOrUpdateAttachment$).toHaveBeenCalledWith('case', 1234,
      { activityCategoryId: 12, activityDate: null, activityId: 1001, activityType: 10, attachmentName: 'testName', attachmentType: undefined, documentId: undefined, fileName: undefined, eventCycle: 1, eventId: 10, filePath: 'Q:\\test.pdf', isPublic: true, language: 1, pageCount: '', sequenceNo: 0, attachmentDescription: 'this is the attachment' });
  });

  it('should save with calls to validate directory', () => {
    component.activityAttachment = sampleData;
    component.viewData = { baseType: 'case', id: 1234, defaultFileName: 'attach.doc' };
    component.ngOnInit();
    component.formGroup.controls.filePath.setValue('Q:\\');
    component.formGroup.controls.filePath.markAsDirty();
    service.validateDirectory$ = jest.fn().mockReturnValue(of(true));
    service.addOrUpdateAttachment$ = jest.fn().mockReturnValue(of({}));
    service.getDeliveryDestination$ = jest.fn().mockReturnValue(of({ directoryName: 'a:\\', fileName: '' }));
    service.getActivity$ = jest.fn().mockReturnValue(of({ activityType: 12, activityCategory: 123 }));
    component.document = 123;

    component.save();
    expect(service.validateDirectory$).toHaveBeenCalledWith('a:\\');
    expect(service.addOrUpdateAttachment$).toHaveBeenCalledWith('case', 1234,
      { activityCategoryId: 123, activityDate: null, activityId: 1001, activityType: 12, attachmentDescription: 'this is the attachment', attachmentName: 'testName', attachmentType: undefined, documentId: 123, eventCycle: 1, eventId: 10, fileName: 'attach.doc', filePath: 'a:\\', isPublic: true, language: 1, pageCount: '', sequenceNo: 0 });
  });

  it('should save without calls to validate path', () => {
    component.activityAttachment = sampleData;
    component.viewData = { baseType: 'case', id: 1234, defaultFileName: 'attach.doc' };
    component.ngOnInit();
    service.validatePath$ = jest.fn().mockReturnValue(of(true));
    service.addOrUpdateAttachment$ = jest.fn().mockReturnValue(of({}));
    component.save();
    expect(service.validatePath$).toHaveBeenCalledTimes(0);
    expect(service.addOrUpdateAttachment$).toHaveBeenCalledWith('case', 1234,
      { activityCategoryId: 12, activityDate: null, activityId: 1001, activityType: 10, attachmentName: 'testName', attachmentType: undefined, documentId: undefined, fileName: undefined, eventCycle: 1, eventId: 10, filePath: 'c:\\abc.pdf', isPublic: true, language: 1, pageCount: '', sequenceNo: 0, attachmentDescription: 'this is the attachment' });
  });

  it('save should validate if the cycle selected is valid', () => {
    component.activityAttachment = { ...sampleData, ...{ eventCycle: 11, currentCycle: 5, eventId: 99, eventIsCyclic: true } };
    component.viewData = { baseType: 'case', id: 1234, defaultFileName: 'attach.doc', event: { id: 9, isCyclic: true, currentCycle: 5, eventCycle: 10 } };
    component.ngOnInit();
    component.initComponent();
    service.validatePath$ = jest.fn().mockReturnValue(of(true));
    service.addOrUpdateAttachment$ = jest.fn().mockReturnValue(of({}));
    component.formGroup.get('eventCycle').setErrors = jest.fn();
    component.formGroup.get('eventCycle').markAsDirty = jest.fn();
    component.save();

    expect(service.addOrUpdateAttachment$).not.toHaveBeenCalled();
    expect(component.formGroup.get('eventCycle').setErrors).toHaveBeenCalledWith({ 'attachmentMaintenance.invalidCycle': true });
    expect(component.formGroup.get('eventCycle').markAsDirty).toHaveBeenCalled();
    expect(cdr.markForCheck).toHaveBeenCalledWith();
  });

  it('save should save cycle only if event is selected', () => {
    component.activityAttachment = { ...sampleData, ...{ eventCycle: 11 } };
    component.viewData = { baseType: 'case', id: 1234, defaultFileName: 'attach.doc', event: { id: 9, isCyclic: true, currentCycle: 5, eventCycle: 1 } };
    component.ngOnInit();
    service.validatePath$ = jest.fn().mockReturnValue(of(true));
    service.addOrUpdateAttachment$ = jest.fn();
    component.formGroup.get('event').setValue({});

    component.save();

    expect(service.addOrUpdateAttachment$).toHaveBeenCalled();
    expect(service.addOrUpdateAttachment$.mock.calls[0][2].eventId).toBeNull();
    expect(service.addOrUpdateAttachment$.mock.calls[0][2].eventCycle).toBeNull();
  });

  describe('Adding another on save', () => {
    it('should reset the form', fakeAsync(() => {
      service.addOrUpdateAttachment$ = jest.fn().mockReturnValue(of({ activityId: 1001, sequenceNo: 0 }));
      component.activityAttachment = sampleData;
      component.viewData = { baseType: 'case', id: 1234, caseId: '1234' };
      component.ngOnInit();
      component.isAdding = true;
      component.isAddAnotherChecked = true;
      component.formGroup.reset = jest.fn();
      component.hasSavedChanges.emit = jest.fn();

      component.save();
      expect(service.addOrUpdateAttachment$).toHaveBeenCalledWith('case', 1234,
        { activityCategoryId: 12, activityDate: null, activityId: 1001, activityType: 10, attachmentName: 'testName', attachmentType: undefined, documentId: undefined, fileName: undefined, eventCycle: 1, eventId: 10, filePath: 'c:\\abc.pdf', isPublic: true, language: 1, pageCount: '', sequenceNo: 0, attachmentDescription: 'this is the attachment' });

      service.addOrUpdateAttachment$('1234', {}).subscribe(() => {
        expect(component.data.activityId).toBeNull();
        expect(component.data.sequenceNo).toBeNull();
        expect(component.formGroup.reset).toHaveBeenCalled();
        expect(component.hasSavedChanges.emit).toHaveBeenCalledWith(true);
      });
      flush();
    }));

    it('should retain activityId after saving in activity context', fakeAsync(() => {
      service.addOrUpdateAttachment$ = jest.fn().mockReturnValue(of({ activityId: 1001, sequenceNo: 0 }));
      component.activityAttachment = sampleData;
      component.ngOnInit();
      component.viewData = { baseType: 'activity', id: 1234, isAdHocGeneration: false };
      component.formGroup.reset = jest.fn();
      component.isAdding = true;
      component.isAddAnotherChecked = true;
      component.save();
      expect(service.addOrUpdateAttachment$).toHaveBeenCalledWith('activity', 1234,
        { activityCategoryId: 12, activityDate: null, activityId: 1001, activityType: 10, attachmentName: 'testName', attachmentType: undefined, documentId: undefined, fileName: undefined, filePath: 'c:\\abc.pdf', isPublic: true, language: 1, sequenceNo: 0, attachmentDescription: 'this is the attachment' });

      service.addOrUpdateAttachment$('1234', {}).subscribe(() => {
        expect(component.originalBaseType).toBe('activity');
        expect(component.baseType).toBe('activity');
        expect(component.data.activityId).toBe(1001);
        expect(component.data.sequenceNo).toBeNull();
        expect(component.formGroup.reset).toHaveBeenCalled();
      });
      flush();
    }));
  });

  describe('delete attachment', () => {
    beforeEach(() => {
      component.activityAttachment = sampleData;
      component.viewData = { baseType: 'case', id: 1 };
      component.ngOnInit();
    });

    it('displays confirmation dialog', () => {
      ipxNotificationService.modalRef.content = { confirmed$: of(false).pipe(delay(1000)) };
      component.deleteAttachment();
      expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalled();
      expect(ipxNotificationService.openDeleteConfirmModal.mock.calls[0][0]).toEqual('attachmentsIntegration.deleteConfirmation');
    });

    it('does not call api to delete attachment if the confirmation is not provided', () => {
      ipxNotificationService.modalRef.content = { confirmed$: of(false).pipe(delay(1000)) };

      component.deleteAttachment();
      expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalled();
      expect(service.deleteAttachment).not.toHaveBeenCalled();
    });

    it('does call api to delete attachment, if confirmation is provided', () => {
      ipxNotificationService.modalRef.content = { confirmed$: of(true) };

      component.deleteAttachment();
      expect(ipxNotificationService.openDeleteConfirmModal).toHaveBeenCalled();
      expect(service.deleteAttachment).toHaveBeenCalledWith('case', 1, sampleData, false);
    });

    it('displays success message if the attachment is deleted successfully', () => {
      ipxNotificationService.modalRef.content = { confirmed$: of(true) };
      service.deleteAttachment = jest.fn().mockReturnValue(of(true));

      component.deleteAttachment();
      expect(notificationService.success).toHaveBeenCalledWith('attachmentsIntegration.deleteSuccess');
      expect(messageService.postLifeCycleMessage).toHaveBeenCalled();
      expect(messageService.postLifeCycleMessage.mock.calls[0][0].action).toEqual('onNavigate');
      expect(messageService.postLifeCycleMessage.mock.calls[0][0].target).toEqual('attachmentMaintenanceHost');
      expect(messageService.postLifeCycleMessage.mock.calls[0][0].payload).toEqual(true);
    });
  });

  describe('on event change', () => {
    beforeEach(() => {
      component.viewData = { baseType: 'case', id: 1234, defaultFileName: 'attach.doc' };
      component.activityAttachment = sampleData;
      component.ngOnInit();
    });

    it('clears and enables cycle when event is cleared', fakeAsync(() => {
      component.formGroup.controls.event.setValue(null);
      tick(100);
      expect(component.formGroup.controls.eventCycle.disabled).toBeFalsy();
      expect(component.formGroup.controls.eventCycle.value).toBe('');
    }));

    it('disables cycle when event is non-cyclic', fakeAsync(() => {
      component.formGroup.controls.event.setValue({ currentCycle: 1, maxCycles: 1 });
      tick(100);
      expect(component.formGroup.controls.eventCycle.disabled).toBeTruthy();
      expect(component.formGroup.controls.eventCycle.value).toBe(1);
    }));

    it('leaves cycle enabled where event is cyclic and validates cycle', fakeAsync(() => {
      component.formGroup.controls.event.setValue({ key: 5678, currentCycle: 2, maxCycles: 10 });
      tick(100);
      expect(component.formGroup.controls.eventCycle.disabled).toBeFalsy();
      expect(component.formGroup.controls.eventCycle.value).toBe(2);

      component.formGroup.controls.eventCycle.setValue(null);
      tick(100);
      expect(component.formGroup.controls.eventCycle.errors).toBeTruthy();

      component.formGroup.controls.eventCycle.setValue('a');
      tick(100);
      expect(component.formGroup.controls.eventCycle.errors).toBeTruthy();

      component.formGroup.controls.eventCycle.setValue(0.2);
      tick(100);
      expect(component.formGroup.controls.eventCycle.errors).toBeTruthy();

      component.formGroup.controls.eventCycle.setValue(0);
      tick(100);
      expect(component.formGroup.controls.eventCycle.errors).toBeTruthy();

      component.formGroup.controls.eventCycle.setValue(-2);
      tick(100);
      expect(component.formGroup.controls.eventCycle.errors).toBeTruthy();

      component.formGroup.controls.eventCycle.setValue(3);
      tick(100);
      expect(component.formGroup.controls.eventCycle.errors).toBeFalsy();
    }));
  });

  describe('setting the base type', () => {
    beforeEach(() => {
      component.baseType = 'activity';
    });

    it('remains as activity if no caseId or nameId provided', () => {
      component.data = {};
      component.setDerivedBaseType();
      expect(component.baseType).toBe('activity');
    });

    it('sets baseType to case if caseId is provided', () => {
      component.data = { activityCaseId: -987 };
      component.setDerivedBaseType();
      expect(component.baseType).toBe('case');
      expect(component.id).toBe(-987);
    });

    it('sets baseType to name if nameId is provided', () => {
      component.data = { activityNameId: 5678 };
      component.setDerivedBaseType();
      expect(component.baseType).toBe('name');
      expect(component.id).toBe(5678);
    });
  });

  describe('case events query', () => {
    it('sets the caseKey', () => {
      component.viewData = { caseId: 5678 };
      const q = component.eventsFor({ stuff: 'stuff' });
      expect(q).toEqual({ caseId: 5678, actionId: '', stuff: 'stuff' });
    });

    it('sets the actionKey where available', () => {
      component.viewData = { caseId: 567, actionKey: 'AND' };
      const q = component.eventsFor({ stuff: 'stuff' });
      expect(q).toEqual({ caseId: 567, actionId: 'AND', stuff: 'stuff' });
    });

    it('external query is set for the events picklist', () => {
      component.viewData = { caseId: 567, actionKey: 'AND', actionName: 'ABCDEFG' };

      const q = component.caseEventsScope();
      expect(q).toEqual({ label: 'caseview.attachments.action', value: 'ABCDEFG' });
      expect(translate.instant).toHaveBeenCalled();
    });
  });
});
