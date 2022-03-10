import { FactoryProvider } from '@angular/core';
const serviceName = '$translate';

export abstract class TranslationService {
    getTranslationTable: (lang: string) => any;
    use: () => any;
    fallbackLanguage: () => Array<string>;
}

export const translationServiceFactory = (injector: ng.auto.IInjectorService) =>
    injector.get(serviceName);

export const translationServiceProvider: FactoryProvider = {
    provide: TranslationService,
    useFactory: translationServiceFactory,
    deps: ['$injector']
};
