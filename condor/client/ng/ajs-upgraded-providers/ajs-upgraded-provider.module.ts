import { ModuleWithProviders } from '@angular/compiler/src/core';
import { NgModule } from '@angular/core';
import { dateHelperProvider } from './date-helper.provider';
import { dateServiceProvider } from './date-service.provider';
import { helpServiceProvider } from './help-service.provider';
import { hotkeysProvider } from './hotkeys.provider';
import { hotkeyServiceProvider } from './hotkeyservice.provider';
import { modalServiceProvider } from './modal-service.provider';
import { notificationServiceProvider } from './notification-service.provider';
import { picklistServiceProvider } from './picklist.service.provider';
import { splitterBuilderServiceProvider } from './splitter.builder-service.provider';
import { storeServiceProvider } from './store.service.provider';
import { translationServiceProvider } from './translation.service.provider';

@NgModule({
  declarations: [],
  exports: []
})

export class AjsUpgradedProviderModule {
  static forRoot(): ModuleWithProviders {
    return {
      ngModule: AjsUpgradedProviderModule,
      providers: [
        translationServiceProvider,
        modalServiceProvider,
        notificationServiceProvider,
        dateServiceProvider,
        dateHelperProvider,
        picklistServiceProvider,
        splitterBuilderServiceProvider,
        storeServiceProvider,
        hotkeysProvider,
        hotkeyServiceProvider,
        helpServiceProvider
      ]
    };
  }
}
