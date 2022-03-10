import { FactoryProvider } from '@angular/core';
const serviceName = 'notificationService';

export abstract class NotificationService {
    buildOptions: any;
    discard: any;
    confirm: any;
    success: any;
    confirmDelete: any;
    ieRequired: (url) => void;
    abstract alert(options: any): any;
    abstract info(options: any): any;
}

export const notificationServiceFactory = (injector: ng.auto.IInjectorService) =>
    injector.get(serviceName);

export const notificationServiceProvider: FactoryProvider = {
    provide: NotificationService,
    useFactory: notificationServiceFactory,
    deps: ['$injector']
};
