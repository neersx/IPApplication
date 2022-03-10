import { ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { SanityCheckMaintenanceServiceMock } from '../sanity-check-maintenance.service.mock';
import { SanityCheckRuleOtherComponent } from './other.component';

describe('EventAndOtherComponent', () => {
  let component: SanityCheckRuleOtherComponent;
  let cdRef: any;
  let sanityService: SanityCheckMaintenanceServiceMock;

  beforeEach(() => {
    cdRef = new ChangeDetectorRefMock();
    sanityService = new SanityCheckMaintenanceServiceMock();
    component = new SanityCheckRuleOtherComponent(cdRef, sanityService as any);
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
    component.formData = { tableColumn: { key: 100 } };
    const result = component.getDataChanges();

    expect(result[component.topic.key]).toEqual({ tableCode: 100 });
  });
});
