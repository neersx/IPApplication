
import { BsModalRefMock, ChangeDetectorRefMock, HotKeysMock } from 'mocks';
import { KeyboardShortcutCheatSheetComponent } from './keyboardshortcutcheatsheet.component';

describe('KeyboardshortcutcheatsheetComponent', () => {
  let component: KeyboardShortcutCheatSheetComponent;
  let hotKeyService: any;

  beforeEach(() => {
    hotKeyService = { hotkeys: jest.spyOn };
    component = new KeyboardShortcutCheatSheetComponent(new ChangeDetectorRefMock() as any, new BsModalRefMock() as any, hotKeyService, new HotKeysMock() as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should format', () => {
    expect(component.format.length).toEqual(1);
  });
});
