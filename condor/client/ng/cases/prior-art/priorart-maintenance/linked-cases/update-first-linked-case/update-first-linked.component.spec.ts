import { FormBuilder, FormGroup } from '@angular/forms';
import { BsModalRefMock, IpxNotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { UpdateFirstLinkedComponent } from './update-first-linked.component';

describe('UpdateFirstLinkedComponent', () => {
  let ipxNotificationService: IpxNotificationServiceMock;
  let selfModalRef: BsModalRefMock;
  let formBuilder: FormBuilder;
  let component: UpdateFirstLinkedComponent;
  let service: {
    getUpdateFirstLinkedCaseViewData$: jest.Mock
  };

  beforeEach(() => {
    ipxNotificationService = new IpxNotificationServiceMock();
    selfModalRef = new BsModalRefMock();
    formBuilder = new FormBuilder();
    service = {
      getUpdateFirstLinkedCaseViewData$: jest.fn().mockReturnValue(of({}))
    };
    component = new UpdateFirstLinkedComponent(selfModalRef as any, formBuilder, service as any, {} as any);
  });

  describe('component', () => {
    it('component is created', () => {
      expect(component).not.toBeNull();
    });
  });

  describe('ngOnInit', () => {
    it('component is created', () => {
        component.caseKeys = [1, 2, 3];
        component.sourceDocumentId = 456;

        component.ngOnInit();

      expect(component.keepCurrent.value).toEqual(false);
      expect(service.getUpdateFirstLinkedCaseViewData$.mock.calls[0][0]).toEqual(expect.objectContaining({caseKeys: component.caseKeys, sourceDocumentId: component.sourceDocumentId});
    });
  });

  describe('apply', () => {
    it('should hide modal and emit proper value on apply', () => {
      (component as any).confirmed$ = { emit: jest.fn() };
      component.formGroup = new FormBuilder().group({
        keepCurrent: true
      });
      component.apply();
      expect(component.confirmed$.emit).toHaveBeenCalledWith({ keepCurrent: true });
      expect(selfModalRef.hide).toHaveBeenCalled();
    });
  });

  describe('cancel', () => {
    it('should hide modal on cancel', () => {
      component.cancel();
      expect(selfModalRef.hide).toHaveBeenCalled();
    });
  });

  describe('getCaseKey', () => {
    it('should return the id of the record', () => {
      const result = component.getCaseKey({ id: 123 });
      expect(result).toEqual(123);
    });
  });
});
