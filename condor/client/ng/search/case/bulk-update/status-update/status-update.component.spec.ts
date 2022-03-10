
import { BsModalServiceMock, ChangeDetectorRefMock } from 'mocks';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { CaseStatusUpdateComponent } from './status-update.component';

describe('CaseStatusUpdateComponent', () => {
  let component: CaseStatusUpdateComponent;
  const changeDetectorRefMock = new ChangeDetectorRefMock();
  const modalService = new BsModalServiceMock();
  beforeEach(() => {
    component = new CaseStatusUpdateComponent(changeDetectorRefMock as any, modalService as any);
    component.formData = {
      isRenewal: false,
      status: ''
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

  it('validate clearCaseStatus', () => {
    component.formData.status = { key: -209 };
    component.clearCaseStatus();
    expect(component.formData.status).toEqual('');
  });

  it('validate discard', () => {
    component.formData.status = { key: -209 };
    component.formData.isRenewal = true;
    component.discard();
    expect(component.formData.status).toEqual('');
    expect(component.formData.isRenewal).toEqual(false);
  });

  it('validate getSaveData with valid status', () => {
    component.formData.status = { key: '-209', value: 'test type', isConfirmationRequired: false };
    component.formData.isRenewal = true;
    const result = component.getSaveData() as any;
    expect(result.renewalStatus.statusCode).toEqual(component.formData.status.key);
    expect(result.renewalStatus.value).toEqual(component.formData.status.value);
    expect(result.renewalStatus.isRenewal).toEqual(true);
    expect(result.renewalStatus.confirmStatus).toEqual(false);
  });

  it('validate getSaveData with status removed', () => {
    component.formData.status = null;
    component.clear = true;
    const result = component.getSaveData() as any;
    expect(result.caseStatus.toRemove).toEqual(true);
  });
  it('validate changeStatus', () => {
    component.formData.status = { key: '-205', value: 'test type', isConfirmationRequired: true };
    component.changeStatus({ key: -205, isConfirmationRequired: true });
    expect(component.modalRef.content.onClose.subscribe).toHaveBeenCalled();
  });

  it('validate openConfirmationDialog', () => {
    component.openConfirmDialog();
    expect(component.modalRef.content.onClose.subscribe).toHaveBeenCalled();
  });

});