import { LocaleService } from 'core/locale.service';
import { WindowParentMessagingService } from './ng/core/window-parent-messaging.service';
import { enableProdMode } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { UrlService, UIRouter } from '@uirouter/core';
import { AppModule } from './ng/app.module';
import * as angular from 'angular';
import { NgModuleRef, NgZone } from '@angular/core';
import { UpgradeModule, downgradeInjectable, downgradeComponent } from '@angular/upgrade/static';
import { TranslateService } from '@ngx-translate/core';
import { TranslationService } from './ng/ajs-upgraded-providers/translation.service.provider';
import { environment } from './ng/environments/environment';
import { jsonUtilities } from './ng/utilities/json-utilities';
import { HotkeysService } from 'angular2-hotkeys';
import { Storage } from './ng/core/storage';
import { AppContextService } from './ng/core/app-context.service';
import { RightBarNavComponent } from './ng/rightbarnav/rightbarnav.component';
import { DueDateComponent } from './ng/search/case/due-date/due-date.component';
import { SearchPresentationPersistenceService } from './ng/search/presentation/search-presentation.persistence.service';

const angularJSAppModule = angular.module('inprotech');

if (environment.production) {
  enableProdMode();
}
platformBrowserDynamic()
  .bootstrapModule(AppModule)
  .then(platformRef => {
    downgradeServices();
    setPostBootstrapinitializations(platformRef);
    bootstrapWithUiRouter(platformRef);
  });

export function syncUiRouter(platformRef: NgModuleRef<any>): void {
  const url: UrlService = platformRef.injector.get(UIRouter).urlService;

  function startUIRouter() {
    url.listen();
    url.sync();
  }

  const ngZone: NgZone = platformRef.injector.get(NgZone);
  ngZone.run(startUIRouter);
}

export function bootstrapWithUiRouter(platformRef: NgModuleRef<any>): void {
  const upgradeModule = platformRef.injector.get(UpgradeModule);
  upgradeModule.bootstrap(document.body, [angularJSAppModule.name]);
}

function downgradeServices() {
  const downgrades = angular.module('inprotech.downgrades');
  downgrades.factory('ngZoneService', downgradeInjectable(NgZone));
  downgrades.factory('HotkeysService', downgradeInjectable(HotkeysService));
  downgrades.factory('dngWindowParentMessagingService', downgradeInjectable(WindowParentMessagingService));
  downgrades.factory('searchPresentationPersistenceService', downgradeInjectable(SearchPresentationPersistenceService));
  // This directive will act as the interface to the "downgraded" Angular component
  downgrades.directive('dngQuickNav', downgradeComponent({ component: RightBarNavComponent }));
  downgrades.directive('dngDueDateSearch', downgradeComponent({ component: DueDateComponent }));
}

function setPostBootstrapinitializations(platformRef: NgModuleRef<any>) {
  angularJSAppModule.run(() => {
    initializeTranslationWithKendoLocales(platformRef)
      .then(() => syncUiRouter(platformRef));
  });
}

function initializeTranslationWithKendoLocales(platformRef: NgModuleRef<any>): angular.IPromise<any> {

  const appContextJs = platformRef.injector.get('$injector').get('appContext');
  return appContextJs.then((ctx) => {
    const s = platformRef.injector.get(Storage) as Storage;
    s.initAppContext(ctx);
    const translate = platformRef.injector.get(TranslateService);
    const service: TranslationService = platformRef.injector.get(TranslationService as any);
    var culture = <string>ctx.user.preferences.culture;
    var fallback = [culture];

    if (culture && culture.length >= 5) {
      fallback.push(culture.substr(0, 2));
    }

    translate.addLangs(fallback);
    fallback.reverse().forEach((cult) => {
      let translationTable = service.getTranslationTable(cult);
      if (translationTable) {
        translate.setTranslation(culture, jsonUtilities.splitKeyedJSONObject(translationTable), true);
      }
    });

    translate.setDefaultLang('en');
    translate.use(service.use());

    loadKendoLocale(platformRef, ctx);

    const appContext = platformRef.injector.get(AppContextService);
    appContext.contextLoaded(ctx);
  });

  function loadKendoLocale(platformRef: NgModuleRef<any>, ctx: any)
  {
      const kendoLocale = ctx.user.preferences.kendoLocale;
      const localeService = platformRef.injector.get(LocaleService) as LocaleService;
      localeService.set(kendoLocale);
  }
}