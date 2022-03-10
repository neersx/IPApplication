import { FactoryProvider } from '@angular/core';
const serviceName = 'hotkeyService';

export abstract class HotkeyService {
    inIt: any;
    reset: any;
    push: any;
    pop: any;
    clone: any;
    add: any;
    get: any;
}

export const hotkeyServiceFactory = (injector: ng.auto.IInjectorService) =>
    injector.get(serviceName);

export const hotkeyServiceProvider: FactoryProvider = {
    provide: HotkeyService,
    useFactory: hotkeyServiceFactory,
    deps: ['$injector']
};
