import { ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { DisplayableNameTypeFieldsHelper } from './displayable-fields';
import { NameDetailsComponent } from './name-details.component';

describe('NameDetailsComponent', () => {
    let c: NameDetailsComponent;
    const displayableFields = new DisplayableNameTypeFieldsHelper();
    let cdr: ChangeDetectorRefMock;
    let service: any;
    const data: any = {
      caseId: 12345,
      details: {
        typeId: 12,
        sequence: false,
        email: 'abc@default.com'
      }
    };

    const emaildata: any = {
      recipientCopiesTo: '',
      subject: 'Test subject',
      body: 'Hello world'
    };

    beforeEach(() => {
      cdr = new ChangeDetectorRefMock();
      service = {
        getFirstEmailTemplate: jest.fn().mockReturnValue(of([emaildata]))
      };
      c = new NameDetailsComponent(displayableFields, service, cdr as any);
      c.show = jasmine.createSpy().and.callThrough();
    });

    it('should call the show function', () => {
      c.show('test');
      expect(c.show).toHaveBeenCalled();
    });
    it('should not call the service if email is blank', () => {
      c.details = { email: '' };
      c.ngOnInit();
      expect(service.getFirstEmailTemplate).not.toHaveBeenCalled();
      expect(c.email).toEqual(undefined);
    });

    it('should call the service and set values', () => {
      c.details = data.details;
      c.caseId = data.caseId;
      c.ngOnInit();
      expect(service.getFirstEmailTemplate).toHaveBeenCalledWith(12345, 12, false);
      expect(c.email.recipientEmail).toBe('abc@default.com');
      expect(c.email.recipientCopiesTo).toBe(emaildata.recipientCopiesTo);
      expect(c.email.subject).toBe(emaildata.subject);
      expect(c.email.body).toBe(emaildata.body);
  });
});