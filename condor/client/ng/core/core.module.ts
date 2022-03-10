import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { APP_INITIALIZER, ModuleWithProviders, NgModule, Optional, SkipSelf } from '@angular/core';
import { AppContextService } from './app-context.service';
import { AppConfigurationService } from './app.config.service';
import { BusService } from './bus.service';
import { CachingInterceptor } from './cache.interceptor';
import { CacheService } from './cache.service';
import { CommonUtilityService } from './common.utility.service';
import { CoreInterceptor } from './core-interceptor';
import { LocalDataStore, SessionDataStore } from './data-store';
import { FeatureDetection } from './feature-detection';
import { KeyBoardShortCutService } from './keyboardshortcut.service';
import { KeyBoardShortCutInitializerService } from './keyboardshortcutinitializer.service';
import { LocalCache } from './local-cache';
import { LocalSettings } from './local-settings';
import { LocaleService } from './locale.service';
import { MessageBroker } from './message-broker';
import { PageTitleService } from './page-title.service';
import { StoreResolvedItemsService } from './storeresolveditems.service';
import { WindowRef } from './window-ref';

// tslint:disable-next-line: only-arrow-functions
export function InitConfigFactory(config: KeyBoardShortCutInitializerService | AppConfigurationService): any {
  return () => config.init();
}

@NgModule()
export class CoreModule {
  constructor(@Optional() @SkipSelf() parentModule: CoreModule) {
    if (parentModule) { throw new Error('CoreModule is already loaded. Import it in the AppModule only'); }
  }

  static forRoot(): ModuleWithProviders<CoreModule> {
    return {
      ngModule: CoreModule,
      providers: [
        AppConfigurationService,
        {
          provide: APP_INITIALIZER,
          useFactory: InitConfigFactory,
          deps: [AppConfigurationService],
          multi: true
        },
        {
          provide: APP_INITIALIZER,
          useFactory: InitConfigFactory,
          deps: [KeyBoardShortCutInitializerService],
          multi: true
        },
        KeyBoardShortCutInitializerService,
        KeyBoardShortCutService,
        BusService,
        LocalSettings,
        LocalCache,
        LocaleService,
        CacheService,
        MessageBroker,
        { provide: HTTP_INTERCEPTORS, useClass: CachingInterceptor, multi: true },
        { provide: HTTP_INTERCEPTORS, useClass: CoreInterceptor, multi: true },
        LocalDataStore,
        SessionDataStore,
        WindowRef,
        AppContextService,
        FeatureDetection,
        PageTitleService,
        CommonUtilityService,
        StoreResolvedItemsService
      ]
    };
  }
}