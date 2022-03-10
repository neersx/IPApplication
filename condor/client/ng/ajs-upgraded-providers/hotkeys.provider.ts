import { FactoryProvider } from '@angular/core';
const serviceName = 'hotkeys';

export abstract class Hotkeys {
    add: any;
    del: any;
    get: any;
    bindTo: any;
    template: any;
    toggleCheatSheet: any;
    includeCheatSheet: any;
    cheatSheetHotkey: any;
    cheatSheetDescription: any;
    useNgRoute: any;
    purgeHotkeys: any;
    templateTitle: any;
    pause: any;
    unpause: any;
}

export const hotkeysFactory = (injector: ng.auto.IInjectorService) =>
    injector.get(serviceName);

export const hotkeysProvider: FactoryProvider = {
    provide: Hotkeys,
    useFactory: hotkeysFactory,
    deps: ['$injector']
};
