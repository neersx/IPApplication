export class TaskPlannerPersistenceServiceMock {
    changedTabSeq$ = {
        next: jest.fn(),
        subscribe: jest.fn()
    };
    tabs = [];
    isTabPersisted = jest.fn();
    persistInitialTabs = jest.fn();
    persistTab = jest.fn();
    getTabs = jest.fn();
    getTabBySequence = jest.fn();
    saveTabs = jest.fn();
    clear = jest.fn();
    saveActiveTab = jest.fn();
    isPicklistSearch = {
        subscribe: jest.fn()
    };
}