export enum RegisterableShortcuts {
  ADD = 'Add',
  REVERT = 'Revert',
  SAVE = 'Save',
  EDIT = 'Edit',
  SEARCH = 'Search'
}

export class ShortcutMetaData {
  combo: string;
  description: string;
}

export const SHORTCUTSMETADATA = new Map<RegisterableShortcuts, ShortcutMetaData>([
  [RegisterableShortcuts.ADD, { combo: 'alt+shift+i', description: 'shortcuts.add' }],
  [RegisterableShortcuts.SAVE, { combo: 'alt+shift+s', description: 'shortcuts.save' }],
  [RegisterableShortcuts.SEARCH, { combo: 'alt+shift+s', description: 'shortcuts.search' }],
  [RegisterableShortcuts.REVERT, { combo: 'alt+shift+z', description: 'shortcuts.revert' }],
  [RegisterableShortcuts.EDIT, { combo: 'enter', description: 'shortcuts.edit' }]
]);