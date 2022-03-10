
import { LocalSettingsMock } from 'core/local-settings.mock';
import { IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs/internal/observable/of';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { AttachmentMaintenanceComponent } from './attachment-maintenance/attachment-maintenance.component';
import { AttachmentServiceMock } from './attachment.service.mock';
import { AttachmentsComponent } from './attachments.component';

describe.only('CriticalDatesComponent', () => {
  let component: AttachmentsComponent;
  let service: AttachmentServiceMock;
  let modal: ModalServiceMock;
  let localSettings: LocalSettingsMock;
  let ipxNotificationService: IpxNotificationServiceMock;
  let notificationService: NotificationServiceMock;
  let ipxDestroy: IpxDestroy;

  beforeEach(() => {
    service = new AttachmentServiceMock();
    modal = new ModalServiceMock();
    localSettings = new LocalSettingsMock();
    ipxNotificationService = new IpxNotificationServiceMock();
    notificationService = new NotificationServiceMock();
    ipxDestroy = of({}) as any;
    component = new AttachmentsComponent(service as any, modal as any, localSettings as any, ipxNotificationService as any, notificationService as any, ipxDestroy);
    component.baseType = 'case';
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('ngOnInit', () => {
    it('should initial  column correctly for internal user', () => {
      component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: false, canEdit: false, canDelete: false }, baseType: 'case', key: null };
      component.ngOnInit();

      const columnFields = component.gridOptions.columns.map(col => col.field);
      expect(columnFields).toEqual(['isPriorArt', 'rawAttachmentName', 'activityType', 'activityCategory', 'activityDate', 'eventDescription', 'eventCycle', 'isPublic', 'attachmentType', 'language', 'pageCount', 'eventNo']);
    });

    it('should initial column correctly for external user', () => {
      component.viewData = { isExternal: true, canMaintainAttachment: { canAdd: false, canEdit: false, canDelete: false }, baseType: 'case', key: null };
      component.ngOnInit();

      const columnFields = component.gridOptions.columns.map(col => col.field);
      expect(columnFields).toEqual(['isPriorArt', 'rawAttachmentName', 'activityType', 'activityCategory', 'activityDate', 'attachmentType', 'language', 'pageCount', 'eventNo', 'eventCycle']);
    });

    it('should initial columns with fixed visibility correctly', () => {
      component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: false, canEdit: false, canDelete: false }, baseType: 'case', key: null };
      component.ngOnInit();

      const columnFields = component.gridOptions.columns.filter(col => col.includeInChooser != null && !col.includeInChooser).map(col => col.field);
      expect(columnFields).toEqual(['isPriorArt', 'rawAttachmentName', 'eventDescription', 'eventCycle', 'attachmentType', 'eventNo']);
    });

    it('should set the defaultfilter for eventNo and eventCycle, if eventDetails are provided', () => {
      component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: false, canEdit: false, canDelete: false }, baseType: 'case', key: null };
      component.eventDetails = {
        eventKey: 10,
        eventCycle: 5,
        actionKey: 'AS'
      };

      component.ngOnInit();
      const eventNoColumn = _.findWhere(component.gridOptions.columns, { field: 'eventNo' });
      expect(eventNoColumn.defaultFilters).toEqual([10]);

      const eventCycleColumn = _.findWhere(component.gridOptions.columns, { field: 'eventCycle' });
      expect(eventCycleColumn.defaultFilters).toEqual([5]);
    });

    it('should call the service on $read', () => {
      component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: false, canEdit: false, canDelete: false }, baseType: 'case', key: 1234 };
      component.ngOnInit();
      const queryParams = 'test';
      component.gridOptions.read$(queryParams as any);

      expect(service.getAttachments$).toHaveBeenCalledWith('case', 1234, queryParams);
    });

    it('should display popup modal on add', () => {
      component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: true, canEdit: false, canDelete: false }, baseType: 'case', key: 1234 };
      component.eventDetails = { eventKey: 19, eventCycle: 1, actionKey: 'A' };
      component.ngOnInit();
      component._caseKey = 1234;
      const result = {
        event: { eventCycle: 1 }
      };
      service.attachmentMaintenanceView$ = jest.fn().mockReturnValue(of(result));
      component.onRowAdd();

      expect(service.attachmentMaintenanceView$).toHaveBeenCalledWith('case', 1234, component.eventDetails);
      expect(modal.openModal).toHaveBeenCalled();
      expect(modal.openModal.mock.calls[0][0]).toEqual(AttachmentMaintenanceComponent);
      expect(modal.openModal.mock.calls[0][1].initialState).toEqual({
        activityAttachment: null,
        activityDetails: {},
        viewData: { baseType: 'case', event: { eventCycle: 1 }, id: 1234 }
      });
    });
    it('should display popup modal on edit', () => {
      component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: false, canEdit: true, canDelete: false }, baseType: 'case', key: 1234 };
      component.eventDetails = { eventKey: 19, eventCycle: 1, actionKey: 'A' };
      component.ngOnInit();
      component._caseKey = 1234;
      const value = {
        event: { eventCycle: 1 }
      };
      const dataItem = { activityId: 1001, sequence: 1, id: 1002 };
      service.getAttachment$.mockReturnValue(of(dataItem));
      service.attachmentMaintenanceView$.mockReturnValue(of(value));
      component.onRowEdit(dataItem);

      expect(service.attachmentMaintenanceView$).toHaveBeenCalledWith('case', 1234, component.eventDetails);
      expect(modal.openModal).toHaveBeenCalled();
      expect(modal.openModal.mock.calls[0][0]).toEqual(AttachmentMaintenanceComponent);
      expect(modal.openModal.mock.calls[0][1].initialState).toEqual({
        activityAttachment: dataItem,
        activityDetails: {},
        viewData: { baseType: 'case', event: { eventCycle: 1 }, id: 1234 }
      });
    });

    describe('context menu', () => {
        it('displays when all permission granted', () => {
            component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: true, canEdit: true, canDelete: true }, baseType: 'case', key: 1234 };
            component.ngOnInit();
            component.displayTaskItems({});

            expect(component.taskItems.length).toBe(2);
            expect(component.taskItems[0].id).toEqual('edit');
            expect(component.taskItems[1].id).toEqual('delete');
            expect(component.gridOptions.showContextMenu).toBeTruthy();
            expect(component.gridOptions.enableGridAdd && component.gridOptions.canAdd && component.gridOptions.gridAddDelegate).toBeTruthy();
        });
        it('displays when only edit permission granted', () => {
            component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: false, canEdit: true, canDelete: false }, baseType: 'case', key: 1234 };
            component.ngOnInit();
            component.displayTaskItems({});

            expect(component.taskItems.length).toBe(1);
            expect(component.taskItems[0].id).toEqual('edit');
            expect(component.gridOptions.showContextMenu).toBeTruthy();
            expect(component.gridOptions.enableGridAdd && component.gridOptions.canAdd && component.gridOptions.gridAddDelegate).toBeFalsy();
        });
        it('displays when only delete permission granted', () => {
            component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: false, canEdit: false, canDelete: true }, baseType: 'case', key: 1234 };
            component.ngOnInit();
            component.displayTaskItems({});

            expect(component.taskItems.length).toBe(1);
            expect(component.taskItems[0].id).toEqual('delete');
            expect(component.gridOptions.showContextMenu).toBeTruthy();
            expect(component.gridOptions.enableGridAdd && component.gridOptions.canAdd && component.gridOptions.gridAddDelegate).toBeFalsy();
        });
        it('is hidden when only add permission granted', () => {
            component.viewData = { isExternal: false, canMaintainAttachment: { canAdd: true, canEdit: false, canDelete: false }, baseType: 'case', key: 1234 };
            component.ngOnInit();
            component.displayTaskItems({});

            expect(component.taskItems.length).toBe(0);
            expect(component.gridOptions.showContextMenu).toBeFalsy();
            expect(component.gridOptions.enableGridAdd && component.gridOptions.canAdd && component.gridOptions.gridAddDelegate).toBeTruthy();
        });
    });
  });
});
