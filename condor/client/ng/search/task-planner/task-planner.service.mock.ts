import { Observable } from 'rxjs';

export class TaskPlannerServiceMock {
  getSearchResultsViewData = jest.fn().mockReturnValue(new Observable());
  getColumns$ = jest.fn().mockReturnValue(new Observable());
  getSavedSearch$ = jest.fn().mockReturnValue(new Observable());
  getSavedSearchQuery = jest.fn().mockReturnValue(new Observable());
  getBelongingToOptions = jest.fn().mockReturnValue(new Observable());
  getReminderComments = jest.fn().mockReturnValue(new Observable());
  getEventNoteTypes$ = jest.fn().mockReturnValue(new Observable());
  getEventNotesDetails$ = jest.fn().mockReturnValue(new Observable());
  reminderCommentsCount = jest.fn().mockReturnValue(new Observable());
  reminderComments = jest.fn().mockReturnValue(new Observable());
  saveReminderComment = jest.fn().mockReturnValue(new Observable());
  isCustomSearch = jest.fn().mockReturnValue(false);
  isPredefinedNoteTypeExist = jest.fn().mockReturnValue(new Observable());
  siteControlId = jest.fn().mockReturnValue(new Observable());
  taskPlannerStateParam = { maintainPublicSearch: true, maintainTaskPlannerSearch: true, maintainTaskPlannerSearchPermission: { update: true, insert: true, delete: true } };
  updateTaskPlannerSearch = jest.fn().mockReturnValue(new Observable());
  isCommentDirty$ = {
    subscribe: jest.fn().mockReturnValue(new Observable()),
    next: jest.fn()
  };
  onActionComplete$ = { next: jest.fn(), subscribe: jest.fn() };
  adHocDateCheckedChangedt$ = { next: jest.fn(), subscribe: jest.fn() };
  getSavedTaskPlannerData = jest.fn().mockReturnValue(new Observable());
  reminderDetailCount$ = { subscribe: jest.fn().mockReturnValue(new Observable()) };
  eventNoteDetailCount$ = { subscribe: jest.fn().mockReturnValue(new Observable()) };
  getUserPreference = jest.fn().mockReturnValue(new Observable());
  setUserPreference = jest.fn().mockReturnValue(new Observable());
  getDueDateResponsibility = jest.fn().mockReturnValue(new Observable());

  rowSelected = { next: jest.fn() };
  hasEmployeeReminder = jest.fn().mockReturnValue(true);
  isReminderOrDueDate = jest.fn().mockReturnValue(true);
  isReminderOrAdHoc = jest.fn().mockReturnValue(true);
  rowSelectedForKot = { next: jest.fn() };
  taskPlannerRowKey = { next: jest.fn() };
  deferReminders = jest.fn().mockReturnValue(new Observable());
  showKeepOnTopNotes = jest.fn().mockReturnValue(new Observable());
  taskPlannerTabs = [{ description: 'My Tasks', key: -27, presentationId: 123, searchName: 'My Tasks' }];
  autoRefreshGrid: boolean;
  previousStateParam = {
    formData: { cases: { caseFamily: { operator: '0', value: { key: 12, code: 'AA', value: 'Test' } } } },
    filterCriteria: {
      searchRequest: {
        dates: {
          useDueDate: 1,
          useReminderDate: 1,
          dateRange: {
            operator: '7',
            from: '01-10-2020',
            to: null
          }
        }
      }
    }
  };
}