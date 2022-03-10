import { FactoryProvider } from '@angular/core';
const serviceName = 'helpService';

export abstract class HelpService {
    get: () => any;
}

export const helpServiceFactory = (injector: ng.auto.IInjectorService) =>
    injector.get(serviceName);

export const helpServiceProvider: FactoryProvider = {
    provide: HelpService,
    useFactory: helpServiceFactory,
    deps: ['$injector']
};
