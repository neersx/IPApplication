import { FormControl, NgForm, Validators } from '@angular/forms';
import { ChangeDetectorRefMock } from 'mocks';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { CaseNameReferenceUpdateComponent } from './case-name-reference-update.component';

describe('NameTypeUpdateComponent', () => {
  let component: CaseNameReferenceUpdateComponent;
  const changeDetectorRefMock = new ChangeDetectorRefMock();

  beforeEach(() => {
    component = new CaseNameReferenceUpdateComponent(changeDetectorRefMock as any);
    component.formData = {
      nameType: '',
      reference: ''
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('validate ngOnInit', () => {
    const caseIds = [11, 12];
    component.topic = new Topic();
    component.topic.params = new TopicParam();
    component.topic.params.viewData = { caseIds };
    component.ngOnInit();
    expect(component.caseIds).toEqual(caseIds);
    expect(component.getSaveData).toEqual(component.getSaveData);
  });
  it('validate discard', () => {
    component.formData.nameType = 'A';
    component.formData.reference = 'test reference';
    component.discard();
    expect(component.formData.nameType).toEqual('');
    expect(component.formData.reference).toEqual('');
  });

  it('validate resetReference', () => {
    component.formData.reference = 'test reference';
    component.resetReference();
    expect(component.formData.reference).toEqual('');
  });

  it('validate isValid with valid data', () => {
    component.formData.nameType = { code: 'A', value: 'Test Name' };
    component.formData.reference = 'test reference';
    component.clear = false;
    component.form = new NgForm(null, null);
    component.form.form.addControl('reference', new FormControl(null, Validators.required));
    const result = component.isValid();
    expect(result).toBeTruthy();
  });

  it('validate isValid with invalid data', () => {
    component.formData.nameType = { code: 'A', value: 'Test Name' };
    component.formData.reference = '';
    component.clear = false;
    component.form = new NgForm(null, null);
    component.form.form.addControl('reference', new FormControl(null, Validators.required));
    const result = component.isValid();
    expect(result).toBeFalsy();
  });

  it('validate getSaveData for case name reference', () => {
    component.formData.nameType = 'A';
    component.formData.reference = 'test reference';
    component.form = new NgForm(null, null);
    component.form.form.addControl('reference', new FormControl(null, Validators.required));
    const result = component.getSaveData() as any;
    expect(result.caseNameReference).toBeDefined();
  });
});
