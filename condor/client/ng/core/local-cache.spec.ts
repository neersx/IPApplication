import { TestBed } from '@angular/core/testing';
import { LocalCache } from './local-cache';
import { Storage } from './storage';
import { StorageMock } from './storage.mock';

describe('Local Cache service', () => {
    let localCache: LocalCache;
    let storage: Storage;
    beforeEach(() => {
        TestBed.configureTestingModule({
          providers: [
            LocalCache,
            { provide: Storage, useClass: StorageMock }
          ]
        });
        localCache = TestBed.inject(LocalCache);
        storage = TestBed.inject(Storage);
      });

      it('should have Cache object generated with correct methods', () => {
        expect(localCache).toBeDefined();
        expect(localCache.keys.caseView.actions.pageNumber).toBeDefined();
        expect(localCache.keys.caseView.actions.pageNumber.get).toEqual('20');
        localCache.keys.caseView.actions.pageNumber.set(50);
        expect(storage.session.set).toHaveBeenCalledWith('caseView.actions.pageNumber', 50);
    });
  });
