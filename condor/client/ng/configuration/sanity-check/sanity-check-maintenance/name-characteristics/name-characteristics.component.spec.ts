import { ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { take } from 'rxjs/operators';
import { SanityCheckMaintenanceServiceMock } from '../sanity-check-maintenance.service.mock';
import { SanityCheckRuleNameCharacteristicsComponent } from './name-characteristics.component';

describe('SanityCheckRuleNameCharacteristicsComponent', () => {
  let component: SanityCheckRuleNameCharacteristicsComponent;
  let cdRef: any;
  let sanityService: SanityCheckMaintenanceServiceMock;

  beforeEach(() => {
    cdRef = new ChangeDetectorRefMock();
    sanityService = new SanityCheckMaintenanceServiceMock();
    component = new SanityCheckRuleNameCharacteristicsComponent(sanityService as any, cdRef);
    component.topic = { key: 'a', getDataChanges: null, setErrors: jest.fn() } as any;
    component.form = { statusChanges: of({}) } as any;
  });

  it('should create', () => {
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
    component.ngOnInit();
    component.formData = {
      name: { key: 10 },
      nameGroup: { key: 11, code: 'B' },
      jurisdiction: { code: 'au', name: 'Australia' },
      category: { id: 11, name: 'c' },
      applyTo: 1,
      typeIsSupplierOnly: true,
      typeIsOrganisation: true,
      typeIsClientOnly: true
    };
    const result = component.getDataChanges();
    const data = result[component.topic.key];

    expect(data.name).toEqual(component.formData.name.key);
    expect(data.nameGroup).toEqual(component.formData.nameGroup.key);
    expect(data.jurisdiction).toEqual(component.formData.jurisdiction.code);
    expect(data.category).toEqual(component.formData.category.key);
    expect(data.isLocal).toEqual(1);
    expect(data.isSupplierOnly).toEqual(component.formData.typeIsSupplierOnly);
    expect(data.entityType.isOrganisation).toBeTruthy();
    expect(data.entityType.isClientOnly).toBeTruthy();
    expect(data.entityType.isIndividual).toBeUndefined();
    expect(data.entityType.isStaff).toBeUndefined();
  });

  it('sets the mandatory attribute for entityType on usedAs change', (done) => {
    component.ngOnInit();
    let last = false;
    component.isTypeOfEntityMandatory$.pipe(take(5)).subscribe({
      next: val => {
        expect(val).toBe(last);
      },
      complete: done()
    });

    component.formData = {
      typeIsStaff: false,
      typeIsClientOnly: false,
      typeIsOrganisation: false,
      typeIsIndividual: false
    };

    component.usedAsChanged();

    component.formData.typeIsStaff = true;
    last = true;
    component.usedAsChanged();

    component.formData.typeIsStaff = false;
    component.formData.typeIsClientOnly = true;
    last = true;
    component.usedAsChanged();

    component.formData.typeIsStaff = false;
    component.formData.typeIsClientOnly = false;
    component.formData.typeIsOrganisation = true;
    last = false;
    component.usedAsChanged();
  });
});
