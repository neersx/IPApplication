import { HttpClientMock } from 'mocks';
import { of } from 'rxjs/internal/observable/of';
import { DmsPersistenceService } from './dms.persistence.service';

describe('Service: DMS Persistence', () => {
    let http: HttpClientMock;
    let service: DmsPersistenceService;
    beforeEach(() => {
        http = new HttpClientMock();
        service = new DmsPersistenceService();
    });

    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });
    describe('hasPersistedFolders', () => {
        it('should check if folders available', () => {
            const node = {
                canHaveRelatedDocuments: true,
                childFolders: [],
                containerId: 'Active!1451',
                database: 'ACTIVE',
                documents: [],
                folderType: 'folders',
                hasChildFolders: true,
                hasDocuments: false,
                id: 1451,
                name: '0001',
                parentId: null,
                siteDbId: '0',
                source: null,
                subClass: null
            };
            const result = service.hasPersistedFolders(node);
            expect(result).not.toBeTruthy();
        });
    });
});
