import { Storage } from './storage';

describe('Storage service', () => {
  let storageService: Storage;
  let localStorageSpy: any;
  let sessionStorageSpy: any;

  beforeEach(() => {
      const localSpy = { get: jest.fn(), set: jest.fn(), remove: jest.fn() };
      const sessionSpy = { get: jest.fn(), set: jest.fn(), remove: jest.fn() };
      localStorage.setItem('preferenceConsented', '1');

      storageService =  new Storage(localSpy as any, sessionSpy as any);
      storageService.initAppContext({ user: { name: 'staffName' } });
      localStorageSpy = localSpy;
      sessionStorageSpy = sessionSpy;
    });

  it('#get for LocalStorage should return stubbed value from a spy', () => {
      const stubValue = 'stub value';
      const key = 'key1';
      localStorageSpy.get.mockReturnValue(stubValue);

      expect(storageService.local.get(key))
        .toBe(stubValue);
      expect(localStorageSpy.get.mock.calls.length)
        .toBe(1);
  });
  it('#get for SessionStorage should return stubbed value from a spy', () => {
      const stubValue = 'stub value';
      const key = 'key1';
      sessionStorageSpy.get.mockReturnValue(stubValue);

      expect(storageService.session.get(key))
        .toBe(stubValue);
      expect(sessionStorageSpy.get.mock.calls.length)
        .toBe(1);
  });
  it('#set for localStorage should set stubbed value from a spy', () => {
      const value = 'value1';
      const key = 'key1';
      storageService.local.set(key, value);
      expect(localStorageSpy.set.mock.calls.length)
        .toBe(1);
  });
  it('#set for SessionStorage should set stubbed value from a spy', () => {
      const value = 'value1';
      const key = 'key1';
      storageService.session.set(key, value);
      expect(sessionStorageSpy.set.mock.calls.length)
        .toBe(1);
  });
  it('#remove show clear the key from storage', () => {
      storageService.local.remove('key');
      expect(localStorageSpy.remove.mock.calls.length)
        .toBe(1);
  });
});
