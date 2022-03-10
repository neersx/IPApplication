import { AppContextServiceMock } from 'core/app-context.service.mock';
import { BehaviorSubjectMock, ChangeDetectorRefMock, NgZoneMock } from 'mocks';
import { DmsComponent } from './dms.component';
import { DmsServiceMock } from './dms.service.mock';

describe('DmsDocument component for Caseview and Nameview', () => {
    let c: DmsComponent;
    let cdRef: ChangeDetectorRefMock;
    let service: DmsServiceMock;
    let persistService: any;
    let setParam: (params?: any) => void;
    let context: AppContextServiceMock;
    let zone: NgZoneMock;
    let messageBroker: {
        subscribe: jest.Mock,
        disconnectBindings: jest.Mock,
        connect: jest.Mock,
        getConnectionId: jest.Mock
    };
    let winRef: any;

    beforeEach(() => {
        persistService = {
            hasPersistedFolders: jest.fn().mockReturnValue(false),
            folders$: new BehaviorSubjectMock(),
            setFoldersData: jest.fn(),
            nodes: [
                {
                    canHaveRelatedDocuments: true,
                    childFolders: [{
                        canHaveRelatedDocuments: true,
                        childFolders: [],
                        containerId: 'Active!1452',
                        database: 'ACTIVE',
                        documents: [],
                        folderType: 'folders',
                        hasChildFolders: true,
                        hasDocuments: false,
                        id: 1451,
                        name: 'child0001',
                        parentId: null,
                        siteDbId: '0',
                        source: null,
                        subClass: null
                    }],
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
                }

            ]
        };
        zone = new NgZoneMock();
        service = new DmsServiceMock();
        cdRef = new ChangeDetectorRefMock();
        context = new AppContextServiceMock();
        winRef = { nativeWindow: { open: jest.fn() } };
        messageBroker = {
            subscribe: jest.fn(),
            disconnectBindings: jest.fn(),
            connect: jest.fn(),
            getConnectionId: jest.fn().mockReturnValue('10')
        };
        c = new DmsComponent(service as any, cdRef as any, messageBroker as any, persistService, winRef);

        setParam = (params?: any) => {
            c.topic = {
                params: {
                    callerType: 'Caseview',
                    viewData: { caseKey: 5 },
                    ...params
                }
            } as any;
        };

        setParam();
    });

    describe('Life cycle', () => {
        it('sets the correct callertype', () => {
            c.ngOnInit();
            expect(c.callerType).toEqual('Caseview');
            expect(c.key).toEqual(5);
        });
        it('should close properly', () => {
            c.ngOnDestroy();
            expect(service.disconnectBindings).toHaveBeenCalled();
        });
    });

    describe('Fetch Folders', () => {
        it('fetchChildren called and retrieved folders from persistence', () => {
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
            c.fetchChildren(node);
            expect(persistService.folder$).toBeUndefined();
            expect(service.getDmsChildFolders$).toBeCalledWith(node.siteDbId, node.containerId, node.folderType, false);
        });
    });

    describe('Child Folders and Documents', () => {
        it('should return empty folder when no documents or childfolders exists', () => {
            const node = {
                childFolders: [],
                folderType: 'folders',
                hasChildFolders: false,
                hasDocuments: false,
                isFolderEmpty: false
            };
            c.hasAnyChidFolderOrDocument(node);
            expect(node.isFolderEmpty).toBeTruthy();
        });
        it('should not return empty folder when either documents or childfolders exists', () => {
            const node = {
                childFolders: [],
                folderType: 'folders',
                hasChildFolders: true,
                hasDocuments: false,
                isFolderEmpty: true
            };
            c.hasAnyChidFolderOrDocument(node);
            expect(node.isFolderEmpty).toBeFalsy();
        });

        it('should not return empty folder when foderType is searchFolder', () => {
            const node = {
                childFolders: [],
                folderType: 'searchFolder',
                hasChildFolders: false,
                hasDocuments: false,
                isFolderEmpty: true
            };
            c.hasAnyChidFolderOrDocument(node);
            expect(node.isFolderEmpty).toBeFalsy();
        });
    });

    describe('LoadDms', () => {
        it('start loading', () => {
            c.ngOnInit();
            jest.useFakeTimers();
            c.loginDms();
            expect(service.loginDms).toHaveBeenCalled();
        });
    });

    describe('openDms', () => {
        it('should handle selection', () => {
            c.ngOnInit();
            c.data = [{
                iwl: 'iwlLink0'
            }, {
                iwl: 'iwlLink1'
            }];
            c.handleSelection({
                index: '1_1', dataItem: {
                    siteDbId: '1'
                }
            });
            expect(c.selectedId).toBeDefined();
            expect(c.selectedId.siteDbId).toEqual('1');
            expect(c.workspaceIwl).toEqual('iwlLink1');
        });
        it('should handle selection', () => {
            c.ngOnInit();
            c.data = [{ iwl: 'irw1' }, { iwl: 'irw2' }];
            c.handleSelection({
                index: '1_1', dataItem: {
                    siteDbId: '1'
                }
            });
            c.openIniManage();
            expect(winRef.nativeWindow.open).toHaveBeenCalledWith('irw2', '_blank');
        });
    });
});