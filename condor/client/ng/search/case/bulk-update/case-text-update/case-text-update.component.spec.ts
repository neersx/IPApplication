
import { ChangeDetectorRefMock } from 'mocks';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { CaseTextUpdateComponent } from './case-text-update.component';

describe('CaseTextUpdateComponent', () => {
  let component: CaseTextUpdateComponent;
  const changeDetectorRefMock = new ChangeDetectorRefMock();
  beforeEach(() => {
    component = new CaseTextUpdateComponent(changeDetectorRefMock as any);
    component.formData = {
      canAppend: true,
      language: '',
      textType: '',
      notes: ''
    };
  });

  it('should create', () => {
    expect(component).toBeDefined();
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

  it('validate resetNotesControl without texttype', () => {
    component.formData.notes = 'test notes';
    component.resetNotesControl();
    expect(component.formData.notes).toEqual('');
  });

  it('validate resetNotesControl with texttype', () => {
    component.formData.notes = 'test notes';
    component.formData.textType = { key: '1' };
    component.resetNotesControl();
    expect(component.formData.notes).toEqual('test notes');
  });

  it('validate clearCaseText', () => {
    component.formData.notes = 'test notes';
    component.clearCaseText();
    expect(component.formData.notes).toEqual('');
  });

  it('validate discard', () => {
    component.formData.language = 'en';
    component.formData.textType = 'test texttype';
    component.formData.notes = 'test notes';
    component.discard();
    expect(component.formData.language).toEqual('');
    expect(component.formData.textType).toEqual('');
    expect(component.formData.notes).toEqual('');
  });

  it('validate getSaveData with valid text type', () => {
    component.formData.textType = { key: 'text11', value: 'test type' };
    component.formData.language = { key: 'en' };
    component.formData.notes = 'test notes';
    component.formData.canAppend = true;
    const result = component.getSaveData() as any;
    expect(result.caseText.language).toEqual(component.formData.language.key);
    expect(result.caseText.textType).toEqual(component.formData.textType.key);
    expect(result.caseText.value).toEqual(component.formData.textType.value);
    expect(result.caseText.notes).toEqual(component.formData.notes);
    expect(result.caseText.canAppend).toEqual(component.formData.canAppend);
  });

  it('validate getSaveData with invalid text type', () => {
    component.formData.textType = undefined;
    component.formData.language = { key: 'en' };
    component.formData.notes = 'test notes';
    const result = component.getSaveData() as any;
    expect(result.caseText).toBeUndefined();
  });

});