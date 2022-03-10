import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { LocalSettingsMocks, NotificationServiceMock, StateServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BulkUpdateComponent } from './bulk-update.component';
import { BulkUpdateServiceMock } from './bulk-update.service.mock';
import { CaseStatusUpdateTopic } from './status-update/status-update.component';

describe('BulkUpdateComponent', () => {
  let component: BulkUpdateComponent;
  const stateServiceMock = new StateServiceMock();
  const bulkUpdateService = new BulkUpdateServiceMock();
  const notificationService = new NotificationServiceMock();
  const modalServiceMock = new ModalServiceMock();
  const localSettingsMock = new LocalSettingsMocks();
  const translateMock = new TranslateServiceMock();
  const commonServiceMock = new CommonUtilityServiceMock();

  beforeEach(() => {
    component = new BulkUpdateComponent(stateServiceMock as any, bulkUpdateService as any, notificationService as any, modalServiceMock as any, localSettingsMock as any, translateMock as any, commonServiceMock as any);
    component.viewData = { caseIds: [] };
    component.previousState = { name: 'search-results', params: '' };
  });

  it('should create', () => {
    expect(component).toBeDefined();
  });

  it('validate ngOnInit', () => {
    component.ngOnInit();
    expect(component.hasPreviousState).toBeTruthy();
    expect(component.topicOptions.topics.length).toEqual(3);
  });

  it('validate ngOnInit for file location update topic', () => {
    component.viewData.canMaintainFileTracking = true;
    component.ngOnInit();
    expect(component.topicOptions.topics.length).toEqual(4);
  });

  it('validate ngOnInit with no case id selected', () => {
    stateServiceMock.params.queryKey = '';
    component.previousState = { name: undefined, params: {} };
    component.ngOnInit();
    expect(component.hasPreviousState).toBeFalsy();
  });

  it('validate save', () => {
    component.save();
    expect(bulkUpdateService.applyBulkUpdateChanges).toHaveBeenCalled();
  });

  it('validate discard on save', () => {

    component.save();
    bulkUpdateService.applyBulkUpdateChanges().subscribe(() => {
      expect(component.discard).toHaveBeenCalled();
    });

  });

  it('validate discard', () => {
    component.ngOnInit();
    component.discard();
    expect(component).toBeDefined();
  });

  it('validate canApply', () => {
    component.ngOnInit();
    const result = component.canApply();
    expect(result).toBeFalsy();
  });

  it('validate canDiscard', () => {
    component.ngOnInit();
    const result = component.canDiscard();
    expect(result).toBeFalsy();
  });

  it('validate openConfirmationDialog', () => {
    component.ngOnInit();
    component.openConfirmationDialog();
    expect(component.modalRef.content.onClose.subscribe).toHaveBeenCalled();
  });

  it('validate case Status topic', () => {
    component.viewData.canUpdateBulkStatus = true;
    component.ngOnInit();
    expect(component.topicOptions.topics[3]).toBeInstanceOf(CaseStatusUpdateTopic);
  });
});