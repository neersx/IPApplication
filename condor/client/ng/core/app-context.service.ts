import { Injectable } from '@angular/core';
import { StateParams } from '@uirouter/angular';
import { ReplaySubject } from 'rxjs';

@Injectable()
export class AppContextService {
  private readonly appContextSubject = new ReplaySubject<AppContext>(1);

  appContext$ = this.appContextSubject.asObservable();
  appContext: AppContext;
  isHosted: boolean;
  isE2e: boolean;

  contextLoaded = (ctx: AppContext) => {
    this.appContext = ctx;
    this.appContextSubject.next(ctx);
  };

  setHomePageState = (state: { name: string, params: StateParams }) => {
    this.appContext.user.preferences.homePageState = state;
  };

  resetHomePageState = () => {
    this.appContext.user.preferences.homePageState = null;
  };
}

export class AppContext {
  [propName: string]: any;
}