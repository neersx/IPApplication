import { DomSanitizer } from '@angular/platform-browser';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock } from 'mocks';
import { DefaultColumnTemplateType } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { DmsServiceMock } from '../dms.service.mock';
import { DmsDocumentComponent } from './dms-documents.component';

describe('IManageDatabaseComponent', () => {
  let component: DmsDocumentComponent;
  let cdRef: ChangeDetectorRefMock;
  let service: DmsServiceMock;
  let grid: IpxKendoGridComponentMock;
  let localSettings: LocalSettingsMock;
  let sanitizerMock: any;

  beforeEach(() => {
    cdRef = new ChangeDetectorRefMock();
    service = new DmsServiceMock();
    localSettings = new LocalSettingsMock();
    sanitizerMock = { bypassSecurityTrustUrl: jest.fn() };
    component = new DmsDocumentComponent(service as any, cdRef as any, sanitizerMock, localSettings);
    grid = new IpxKendoGridComponentMock();
    component.selectedId = {
      databaseId: 1,
      containerId: 'TPSDK!232',
      folderType: 'folder',
      canHaveRelatedDocuments: true
    };
    component.grid = grid as any;
    component.templates = [{ name: 'abc' }] as any;
    component.callerType = 'CaseView';
    component.ngOnInit();

    return component;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
    expect(component.gridOptions).toBeDefined();
  });

  it('should build columns', () => {
    component.gridOptions._search = jest.fn();
    component.ngOnChanges({ selectedId: { currentValue: {} } } as any);
    expect(component.gridOptions._search).toHaveBeenCalled();
    expect(component.gridOptions.columns).toEqual(
      [
        {
          title: 'Type',
          field: 'applicationExtension',
          template: true,
          sortable: false,
          width: 30
        }, {
          title: '',
          iconName: 'paperclip',
          field: 'hasAttachments',
          template: true,
          sortable: false
        }, {
          title: 'caseview.caseDocumentManagementSystem.documentColumns.description',
          field: 'description',
          sortable: false,
          template: true,
          width: 300
        }, {
          title: 'caseview.caseDocumentManagementSystem.documentColumns.version',
          template: false,
          field: 'version',
          sortable: false
        }, {
          title: 'caseview.caseDocumentManagementSystem.documentColumns.staffMember',
          field: 'authorFullName',
          sortable: false
        }, {
          title: 'caseview.caseDocumentManagementSystem.documentColumns.docType',
          field: 'docTypeDescription',
          sortable: false,
          width: 100
        }, {
          title: 'caseview.caseDocumentManagementSystem.documentColumns.dateEdited',
          field: 'dateEdited',
          template: true,
          sortable: false,
          width: 150
        }, {
          title: 'caseview.caseDocumentManagementSystem.documentColumns.dateCreated',
          field: 'dateCreated',
          template: true,
          sortable: false,
          width: 150
        }, {
          title: 'caseview.caseDocumentManagementSystem.documentColumns.size',
          field: 'size',
          template: true,
          sortable: false,
          width: 70
        }, {
          title: 'caseview.caseDocumentManagementSystem.documentColumns.docNumber',
          field: 'id',
          defaultColumnTemplate: DefaultColumnTemplateType.number,
          sortable: false
        }]);
  });

  it('should build expand row correctly', () => {
    component.expandRow({
      dataItem: {
        siteDbId: 1,
        containerId: 'TPSDK!1001',
        relatedDocuments: []
      },
      expand: true
    });
    expect(service.getDmsDocumentDetails$).toHaveBeenCalledWith(1, 'TPSDK!1001');
  });

  it('should build expand row correctly', () => {
    component.expandRow({
      dataItem: {
        siteDbId: 1,
        containerId: 'TPSDK!1001',
        relatedDocuments: []
      },
      expand: true
    });
    expect(service.getDmsDocumentDetails$).toHaveBeenCalledWith(1, 'TPSDK!1001');
  });

  it('should call the collapseRow when page changed', () => {
    component.onPageChanged();
    expect(component.grid.collapseAll).toHaveBeenCalled();
  });

  it('should pass string for sanitization', () => {
    component.sanitize('theString');
    expect(sanitizerMock.bypassSecurityTrustUrl).toHaveBeenCalledWith('theString');
  });
});
