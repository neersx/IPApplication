import { async } from '@angular/core/testing';
import { SearchPresentationData } from './search-presentation.model';
import { SearchPresentationPersistenceService } from './search-presentation.persistence.service';

describe('SearchPresentationPersistenceService', () => {
    let service: SearchPresentationPersistenceService;
    beforeEach(() => {
        service = new SearchPresentationPersistenceService();
    });

    it('should create the service instance', async(() => {
        expect(service).toBeTruthy();
    }));

    it('verify setSearchPresentationData method without key', async(() => {
        const data = new SearchPresentationData();
        service.setSearchPresentationData(data);
        expect(service.getSearchPresentationData()).toEqual(data);
    }));

    it('verify setSearchPresentationData method with key', async(() => {
        const data = new SearchPresentationData();
        service.setSearchPresentationData(data, 'key1');
        expect(service.getSearchPresentationData('key1')).toEqual(data);
    }));

    it('verify setSearchPresentationData method with unknown key', async(() => {
        service.setSearchPresentationData(new SearchPresentationData(), 'key1');
        expect(service.getSearchPresentationData('key2')).toBeUndefined();
    }));

});