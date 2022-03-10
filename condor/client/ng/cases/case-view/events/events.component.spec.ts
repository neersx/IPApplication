import { ChangeDetectorRef } from '@angular/core';
import { AttachmentModalServiceMock } from 'common/attachments/attachment-modal.service.mock';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { BusService } from 'core/bus.service';
import { LocalSettings } from 'core/local-settings';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { BusMock } from 'mocks/bus.mock';
import { ChangeDetectorRefMock } from 'mocks/change-detector-ref.mock';
import { of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { CaseDetailService } from '../case-detail.service';
import { CaseDetailServiceMock } from '../case-detail.service.mock';
import { CaseViewViewData } from '../view-data.model';
import { CaseviewEventsComponent } from './events.component';
import { CaseViewEventsService } from './events.service';
import { CaseViewEventsServiceMock } from './events.service.mock';

describe('EventsComponent', () => {
  let component: (eventType: string, viewData?: CaseViewViewData) => CaseviewEventsComponent;
  let localSettings: LocalSettings;
  let caseViewEventsService: CaseViewEventsService;
  let caseDetailService: CaseDetailService;
  let cdr: ChangeDetectorRef;
  let bus: BusService;
  let attachmentModalService: AttachmentModalServiceMock;
  let destroy$: IpxDestroy;
  let appContextService: AppContextServiceMock;

  const availableEventTypes = {
    due: 'due',
    occurred: 'occurred'
  };

  beforeEach(() => {
    localSettings = new LocalSettingsMock();
    caseViewEventsService = new CaseViewEventsServiceMock() as any;
    caseDetailService = new CaseDetailServiceMock() as any;
    cdr = new ChangeDetectorRefMock() as any;
    bus = new BusMock();
    attachmentModalService = new AttachmentModalServiceMock() as any;
    destroy$ = of({}) as any;
    appContextService = new AppContextServiceMock() as any;

    component = (eventType: string, viewData?: CaseViewViewData): CaseviewEventsComponent => {
      const c = new CaseviewEventsComponent(localSettings, caseViewEventsService, caseDetailService, cdr, bus, attachmentModalService as any, destroy$, appContextService as any);

      c.topic = {
        params: {
          viewData: viewData || { caseKey: 1 }, eventType
        }, key: '', title: '', component: null
      };

      caseDetailService.getImportanceLevelAndEventNoteTypes$ = jest.fn().mockReturnValue(of({
        importanceLevel: 2,
        importanceLevelOptions:
          [{ code: 1, description: 'imp1' },
          { code: 2, description: 'imp2' }],
        requireImportanceLevel: false,
        eventNoteTypes: [{ test: 'abc' }]
      }));

      c.grid = new IpxKendoGridComponentMock() as any;

      return c;
    };
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  const testInit = (eventType) => {
    const c = component(eventType);
    c.ngOnInit();
    expect(c.gridOptions).toBeDefined();

    return c;
  };

  const testColumnFieldsWithoutNotes = (eventType) => {
    const c = component(eventType);
    c.ngOnInit();
    expect(c.gridOptions).toBeDefined();
    expect(c.gridOptions.columns.length).toBe(4);
    expect(c.gridOptions.columns[1].field).toBe('eventDate');
    expect(c.gridOptions.columns[2].field).toBe('eventDescription');
  };

  const testColumnFieldsWithNotes = (eventType) => {
    caseDetailService.getImportanceLevelAndEventNoteTypes$ = jest.fn().mockReturnValue({
      importanceLevel: 2,
      importanceLevelOptions:
        [{ code: 1, description: 'imp1' },
        { code: 2, description: 'imp2' }],
      requireImportanceLevel: false,
      eventNoteTypes: [{ test: 'abc' }]
    });

    const c = component(eventType);
    c.ngOnInit();
    expect(c.gridOptions).toBeDefined();
    expect(c.gridOptions.columns.length).toBe(4);
    expect(c.gridOptions.columns[0].field).toBe('hasNotes');
    expect(c.gridOptions.columns[1].field).toBe('eventDate');
    expect(c.gridOptions.columns[2].field).toBe('eventDescription');
    expect(c.gridOptions.columns[3].field).toBe('defaultEventText');
  };

  it('should initialise grid options for due events', () => {
    testInit(availableEventTypes.due);
  });

  it('should initialise grid options for occurred events', () => {
    testInit(availableEventTypes.occurred);
  });

  it('ensure correct column order for due events', () => {
    testColumnFieldsWithoutNotes(availableEventTypes.due);
  });

  it('ensure correct column order for occurred events', () => {
    testColumnFieldsWithoutNotes(availableEventTypes.occurred);
  });

  it('ensure correct column order for due events when notes are available', () => {
    testColumnFieldsWithNotes(availableEventTypes.due);
  });

  it('ensure correct column order for occurred events when notes are available', () => {
    testColumnFieldsWithNotes(availableEventTypes.occurred);
  });

  it('should have correct gridoptions for due events', () => {
    const c = testInit(availableEventTypes.due);
    const o = c.gridOptions;
    expect(o.pageable.pageSizeSetting).toBe(localSettings.keys.caseView.events.due.pageSize);
    expect(o.columnSelection.localSetting).toBe(localSettings.keys.caseView.events.due.columnsSelection);
    o.read$();
    expect(caseViewEventsService.getCaseViewDueEvents).toHaveBeenCalled();
    c.importanceLevel = 50;
    c.changeImportanceLevel();
    expect(localSettings.keys.caseView.events.due.importanceLevelCacheKey.getSessionValue()).toBe(c.importanceLevel);
  });
  it('should have correct gridoptions for occurred events', () => {
    const c = testInit(availableEventTypes.occurred);
    const o = c.gridOptions;
    expect(o.pageable.pageSizeSetting).toBe(localSettings.keys.caseView.events.occurred.pageSize);
    expect(o.columnSelection.localSetting).toBe(localSettings.keys.caseView.events.occurred.columnsSelection);
    o.read$();
    expect(caseViewEventsService.getCaseViewOccurredEvents).toHaveBeenCalled();
    c.importanceLevel = 50;
    c.changeImportanceLevel();
    expect(localSettings.keys.caseView.events.occurred.importanceLevelCacheKey.getSessionValue()).toBe(c.importanceLevel);
  });

  it('change importance level', () => {
    const c = component(availableEventTypes.occurred);
    c.ngOnInit();
    expect(c.changeImportanceLevel).toBeDefined();
    c.changeImportanceLevel();

    expect(c.grid.search).toHaveBeenCalled();
  });

  it('gets importance level from cache', () => {
    localSettings.keys.caseView.importanceLevelCacheKey.setSession(6);
    const c = component(availableEventTypes.occurred);
    c.ngOnInit();
    expect(c.gridOptions).toBeDefined();
    expect(caseDetailService.getImportanceLevelAndEventNoteTypes$).toHaveBeenCalled();

    expect(c.importanceLevel).toBe(2);
  });

  it('uses default importance level if cache value not present', () => {
    const c = component(availableEventTypes.occurred);
    c.ngOnInit();
    expect(c.gridOptions).toBeDefined();
    expect(caseDetailService.getImportanceLevelAndEventNoteTypes$).toHaveBeenCalled();

    expect(c.importanceLevel).toBe(2);
  });

  it('should set isExternal to true when rootScope has user with isexternal true', () => {
    appContextService.appContext = { user: { isExternal: true } };

    const c = component(availableEventTypes.occurred);
    c.ngOnInit();
    expect(c.isExternal).toBe(true);
  });

  it('should display attachment modal', () => {
    const c = component(availableEventTypes.occurred);
    c.viewData = { caseKey: 1 };
    c.openAttachmentWindow({ eventNo: 111, cycle: 2, createdByAction: 'A' });

    expect(attachmentModalService.displayAttachmentModal).toHaveBeenCalled();
    expect(attachmentModalService.displayAttachmentModal.mock.calls[0][0]).toBe('case');
    expect(attachmentModalService.displayAttachmentModal.mock.calls[0][1]).toBe(1);
    expect(attachmentModalService.displayAttachmentModal.mock.calls[0][2]).toEqual({
      actionKey: 'A',
      eventKey: 111,
      eventCycle: 2
    });
  });

  it('should display add attachment modal', () => {
    const c = component(availableEventTypes.occurred);
    c.viewData = { caseKey: 1 };

    c.addAttachment({ eventNo: 111, cycle: 2, createdByAction: 'A' });

    expect(attachmentModalService.triggerAddAttachment).toHaveBeenCalled();
    expect(attachmentModalService.triggerAddAttachment.mock.calls[0][0]).toBe('case');
    expect(attachmentModalService.triggerAddAttachment.mock.calls[0][1]).toBe(1);
    expect(attachmentModalService.triggerAddAttachment.mock.calls[0][2]).toEqual({
      actionKey: 'A',
      eventKey: 111,
      eventCycle: 2
    });
  });
});