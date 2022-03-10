import { FactoryProvider } from '@angular/core';
const serviceName = 'modalService';

export abstract class ModalService {
    getRegistry: any;
    open: any;
    isOpen: any;
    getInstance: any;
    register: any;
    openModal: any;
    close: any;
    cancel: any;
    canOpen: any;
}

export const modalServiceFactory = (injector: ng.auto.IInjectorService) =>
    injector.get(serviceName);

export const modalServiceProvider: FactoryProvider = {
    provide: ModalService,
    useFactory: modalServiceFactory,
    deps: ['$injector']
};
