import { CaseValidCombinationServiceMock, ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { skip } from 'rxjs/operators';
import { SanityCheckMaintenanceServiceMock } from '../sanity-check-maintenance.service.mock';
import { SanityCheckRuleCaseCharacteristicsComponent } from './case-characteristics.component';
jest.useFakeTimers();
describe('CaseCharacteristicsComponent', () => {
  let component: SanityCheckRuleCaseCharacteristicsComponent;
  let cdRef: any;
  let cvs: any;
  let validatorService: any;
  let sanityService: SanityCheckMaintenanceServiceMock;

  beforeEach(() => {
    cvs = new CaseValidCombinationServiceMock();
    validatorService = { validateCaseCharacteristics$: jest.fn(), build: jest.fn() } as any;
    cdRef = new ChangeDetectorRefMock();
    sanityService = new SanityCheckMaintenanceServiceMock();
    component = new SanityCheckRuleCaseCharacteristicsComponent(cdRef, sanityService as any, cvs, validatorService);
    component.topic = { key: 'a', getDataChanges: null, setErrors: jest.fn() } as any;
    component.form = { statusChanges: of({}) } as any;
  });

  it('should create and initialise the component', () => {
    component.ngOnInit();
    expect(component).toBeTruthy();
    expect(component.appliesToOptions.length).toBe(2);
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
    const charData = { caseType: 'ABCD' };
    validatorService.build.mockReturnValue(charData);
    component.form = { value: { a: 'a' } } as any;
    component.formData = { includeDead: true };
    const result = component.getDataChanges();

    expect(validatorService.build).toHaveBeenCalledWith(component.form.value);
    expect(result[component.topic.key]).toEqual({ ...charData, ...component.formData });
  });

  it('verifyCaseCategoryStatus should correctly call isCaseCategoryDisabled with right flag', done => {
    component.ngOnInit();
    let isDisabled = true;

    component.isCaseCategoryDisabled.subscribe(val => {
      expect(val).toEqual(isDisabled);

      if (!isDisabled) {
        done();
      }
    });

    component.formData = { ...component.formData, caseType: { code: 'A' }, caseTypeExclude: true };
    component.verifyCaseCategoryStatus();

    component.formData = { ...component.formData, caseType: { code: 'A' }, caseTypeExclude: false };
    isDisabled = false;
    component.verifyCaseCategoryStatus();
  });

  it('on criteria changes, calls validator service', () => {
    component.formData = { caseType: 'A', caseTypeExcluded: true };
    validatorService.validateCaseCharacteristics$.mockReturnValue({
      then: jest.fn().mockImplementation((x) => {
        x();
      })
    });
    component.isCaseCategoryDisabled.pipe(skip(1)).subscribe((val) => {
      expect(val).toBeFalsy();
    });

    component.onCriteriaChange();
    jest.runAllTimers();

    expect(validatorService.validateCaseCharacteristics$).toHaveBeenCalled();
    expect(component.formData.jurisdictionExclude).toBeNull();
    expect(component.formData.propertyTypeExclude).toBeNull();
    expect(component.formData.caseCategoryExclude).toBeNull();
    expect(component.formData.subTypeExclude).toBeNull();
    expect(component.formData.basisExclude).toBeNull();
  });

  it('handles changes for status checkboxes, if status dead changed', () => {
    component.formData = { statusIncludeDead: true, statusIncludePending: true, statusIncludeRegistered: true };
    component.statusChanged(true);
    expect(component.formData.statusIncludePending).toBeNull();
    expect(component.formData.statusIncludeRegistered).toBeNull();
    expect(cdRef.markForCheck).toHaveBeenCalled();

    component.formData = { statusIncludeDead: false, statusIncludePending: true, statusIncludeRegistered: true };
    component.statusChanged(true);
    expect(component.formData.statusIncludePending).toBeTruthy();
    expect(component.formData.statusIncludeRegistered).toBeTruthy();
  });

  it('handles changes for status checkboxes, if pending or registered status changed', () => {
    component.formData = { statusIncludeDead: true, statusIncludePending: true, statusIncludeRegistered: true };
    component.statusChanged(false);
    expect(component.formData.statusIncludePending).toBeTruthy();
    expect(component.formData.statusIncludeRegistered).toBeTruthy();
    expect(component.formData.statusIncludeDead).toBeNull();
  });
});
