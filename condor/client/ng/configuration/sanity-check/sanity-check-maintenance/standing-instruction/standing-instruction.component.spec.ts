import { ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { SanityCheckMaintenanceServiceMock } from '../sanity-check-maintenance.service.mock';
import { SanityCheckRuleStandingInstructionComponent } from './standing-instruction.component';

describe('StandingInstructionComponent', () => {
  let component: SanityCheckRuleStandingInstructionComponent;
  let cdRef: any;
  let sanityService: SanityCheckMaintenanceServiceMock;

  beforeEach(() => {
    cdRef = new ChangeDetectorRefMock();
    sanityService = new SanityCheckMaintenanceServiceMock();
    component = new SanityCheckRuleStandingInstructionComponent(cdRef, sanityService as any);
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
    component.formData = { instructionType: { code: 'A', key: 100 }, characteristic: { id: 9 } };
    const result = component.getDataChanges();

    expect(result[component.topic.key]).toEqual({ instructionType: 'A', characteristics: 9 });
  });

  it('characteristicsFor, should extend query to include selected instruction type', () => {
    component.ngOnInit();
    component.formData = { ...component.formData, instructionType: { code: 'ABCD' } };
    const result = component.characteristicsExtendQuery({});
    expect(result.instructionTypeCode).toEqual('ABCD');
  });

  it('isInstructionTypeSelected fires value, depending on call to instructionTypeSelected', done => {
    let isSelected = false;
    component.formData = {};
    component.isInstructionTypeSelected.subscribe((val) => {
      expect(val).toEqual(isSelected);

      if (isSelected) {
        done();
      }
    });

    component.instructionTypeSelected(isSelected);

    isSelected = true;
    component.instructionTypeSelected(isSelected);
  });
});
