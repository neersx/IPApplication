import { FactoryProvider } from '@angular/core';
const serviceName = 'store';

export abstract class StoreService {
    getPrefix: any;
    // tslint:disable-next-line:variable-name
    InMemoryStorage: any;
    // tslint:disable-next-line:variable-name
    Store: any;
    local: any;
    session: any;
}

export const storeServiceFactory = (injector: ng.auto.IInjectorService) =>
    injector.get(serviceName);

export const storeServiceProvider: FactoryProvider = {
    provide: StoreService,
    useFactory: storeServiceFactory,
    deps: ['$injector']
};
