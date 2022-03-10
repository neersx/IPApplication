import { Injectable } from '@angular/core';
import { DataStore, InMmeoryDataStore, LocalDataStore, SessionDataStore } from './data-store';

export class Store {
  readonly store: DataStore;
  readonly userName: string;
  private getUserName = (): string => '';

  constructor(private readonly storage: DataStore) {
    this.store = storage;
  }

  initAppContext(ctx: { user: { name: string } }): void {
    this.getUserName = () => ctx.user.name;
  }

  getPrefix(): string {
    return 'inprotech[user=' + this.getUserName() + '].';
  }

  setWithoutPrefix = (key: any, value: any) => {
    this.store.set(key, value);
  };

  set = (key: any, value: any) => {
    this.store.set(this.getPrefix() + key, value);
  };

  get(key: any): any {
    try {
      return this.store.get(this.getPrefix() + key);
    } catch (e) {
      // tslint:disable-next-line:no-null-keyword
      return null;
    }
  }

  remove = (key: any) => {
    this.store.remove(this.getPrefix() + key);
  };
}

@Injectable({
  providedIn: 'root'
})
export class Storage {
  local: Store;
  session: Store;
  constructor(private readonly localStore: LocalDataStore, private readonly sessionStore: SessionDataStore) {
    const hasProvidedConsent = localStorage.getItem('preferenceConsented') === '1';
    this.local = new Store(hasProvidedConsent ? localStore : new InMmeoryDataStore());
    this.session = new Store(hasProvidedConsent ? sessionStore : new InMmeoryDataStore());
  }

  initAppContext(ctx: { user: { name: string } }): void {
    this.local.initAppContext(ctx);
    this.session.initAppContext(ctx);
  }
}
