import { RegisterableShortcuts, SHORTCUTSMETADATA } from 'core/registerable-shortcuts.enum';
import { HotKeysMock } from 'mocks';
import { IpxShortcutsService } from './ipx-shortcuts.service';

describe('Service: IpxGridShortcuts', () => {
  let service: IpxShortcutsService;
  let hotKeysService: HotKeysMock;
  beforeEach(() => {
    hotKeysService = new HotKeysMock();
    service = new IpxShortcutsService(hotKeysService as any);
  });
  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  it('registers each key with hotkeys service', () => {
    service.observeMultiple$([RegisterableShortcuts.ADD, RegisterableShortcuts.REVERT]).subscribe();
    const dataForAdd = SHORTCUTSMETADATA.get(RegisterableShortcuts.ADD);
    const dataForRevert = SHORTCUTSMETADATA.get(RegisterableShortcuts.REVERT);
    expect(hotKeysService.add).toHaveBeenCalledTimes(2);
    expect(hotKeysService.add.mock.calls[0][0].combo[0]).toEqual(dataForAdd.combo);
    expect(hotKeysService.add.mock.calls[1][0].combo[0]).toEqual(dataForRevert.combo);
  });

  it('does not re-register a key with hotkeys service', () => {
    const dataForAdd = SHORTCUTSMETADATA.get(RegisterableShortcuts.ADD);

    service.observeMultiple$([RegisterableShortcuts.ADD]).subscribe();
    hotKeysService.hotkeys = [{ combo: [dataForAdd.combo] }];

    service.observeMultiple$([RegisterableShortcuts.ADD]).subscribe();
    service.observeMultiple$([RegisterableShortcuts.ADD]).subscribe();

    expect(hotKeysService.add).toHaveBeenCalledTimes(1);
  });

  it('raises the event for all observers on hotkeys service callback', done => {
    service.observeMultiple$([RegisterableShortcuts.ADD, RegisterableShortcuts.REVERT])
      .subscribe((key) => {
        expect(key).toEqual(RegisterableShortcuts.ADD);
        done();
      });

    expect(hotKeysService.add).toHaveBeenCalledTimes(2);
    hotKeysService.addedKeys[0].callback();
  });
});
