import { async, TestBed } from '@angular/core/testing';
import { LocalSettings } from './local-settings';
import { Storage } from './storage';
import { StorageMock } from './storage.mock';

describe('Local Settings service', () => {
  let localSettings: LocalSettings;
  let storage: Storage;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      providers: [
        LocalSettings,
        { provide: Storage, useClass: StorageMock }
      ]
    });
    storage = TestBed.get(Storage);
    localSettings = TestBed.get(LocalSettings);
  }));

  it('should have settings object generated with correct methods', () => {
    expect(localSettings).toBeDefined();
    expect(localSettings.keys.caseView.actions.pageNumber).toBeDefined();
    expect(localSettings.keys.caseView.actions.pageNumber.getLocal).toEqual(5);
    localSettings.keys.caseView.actions.pageNumber.setLocal(20);
    expect(storage.local.set).toHaveBeenCalledWith('caseView.actions.pageNumber', 20);
  });

  it('should accept suffix', () => {
    const spy = jest.spyOn(storage.local, 'get');
    expect(localSettings.keys.caseView.actions.pageNumber).toBeDefined();
    localSettings.keys.caseView.actions.pageNumber.setLocal(20, 'test');
    expect(storage.local.set).toHaveBeenCalledWith('caseView.actions.pageNumbertest', 20);
    localSettings.keys.caseView.actions.pageNumber.getLocalwithSuffix('test');
    expect(spy.mock.calls.pop()[0]).toBe('caseView.actions.pageNumbertest');
  });
});
