import { ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { SanityCheckRuleCaseNameComponent } from '../case-name/case-name.component';
import { SanityCheckMaintenanceServiceMock } from '../sanity-check-maintenance.service.mock';
import { SanityCheckRuleEventComponent } from './event.component';

describe('EventAndOtherComponent', () => {
  let component: SanityCheckRuleEventComponent;
  let cdRef: any;
  let sanityService: SanityCheckMaintenanceServiceMock;

  beforeEach(() => {
    cdRef = new ChangeDetectorRefMock();
    sanityService = new SanityCheckMaintenanceServiceMock();
    component = new SanityCheckRuleEventComponent(cdRef, sanityService as any);
    component.topic = { key: 'sanity-event', getDataChanges: null, setErrors: jest.fn() } as any;
    component.form = { statusChanges: of({}) } as any;
  });

  it('should create and initialise the component', () => {
    component.ngOnInit();
    expect(component).toBeTruthy();
  });

  it('handles status changes and sets errors appropriatly', () => {
    component.form = { statusChanges: of({}), dirty: true, invalid: true, valid: false } as any;
    component.ngOnInit();

    expect(component.topic.hasChanges).toBeTruthy();
    expect(component.topic.setErrors).toHaveBeenCalledWith(true);
    expect(sanityService.raiseStatus.mock.calls[0][0]).toEqual(component.topic.key);
    expect(sanityService.raiseStatus.mock.calls[0][1]).toBeTruthy();
    expect(sanityService.raiseStatus.mock.calls[0][2]).toBeTruthy();
    expect(sanityService.raiseStatus.mock.calls[0][3]).toBeFalsy();
  });

  it('gets data changes', () => {
    component.formData = { event: { key: 100 }, eventIncludeDue: false, eventIncludeOccurred: true };
    const result = component.getDataChanges();

    expect(result[component.topic.key]).toEqual({ eventNo: 100, includeDue: false, includeOccurred: true });
  });

  it('resets include checkboxes', () => {
    component.formData = { event: null, includeDue: false, includeOccurred: true };
    component.eventSet();

    expect(component.formData.eventIncludeDue).toBeNull();
    expect(component.formData.eventIncludeOccurred).toBeNull();
  });
});