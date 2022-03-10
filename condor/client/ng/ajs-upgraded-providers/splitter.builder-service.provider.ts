import { FactoryProvider, NgModule } from '@angular/core';

export abstract class SplitterBuilder {
    defaultOptions: any;
// tslint:disable-next-line: variable-name
    BuildOptions: any;
}

export const splitterBuilderServiceFactory = (service: ng.auto.IInjectorService) => service.get('splitterBuilder');

export const splitterBuilderServiceProvider: FactoryProvider = {
    provide: SplitterBuilder,
    useFactory: splitterBuilderServiceFactory,
    deps: ['$injector']
};
