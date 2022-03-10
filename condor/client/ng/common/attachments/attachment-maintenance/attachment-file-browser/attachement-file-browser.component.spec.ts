import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { DefaultColumnTemplateType } from 'shared/component/grid/ipx-grid.models';
import { AttachmentServiceMock } from '../../attachment.service.mock';
import { AttachmentFileBrowserComponent } from './attachement-file-browser.component';
import { AttachmentFileBrowserServiceMock } from './attachment-file-browser.service.mock';

describe('AttachementFileBrowserComponent', () => {
  let component: AttachmentFileBrowserComponent;

  let service: AttachmentFileBrowserServiceMock;
  let cdr: any;
  let bsModalRef: any;
  let modal: any;
  let attachmentService: any;

  beforeEach(() => {
    bsModalRef = new BsModalRefMock();
    cdr = new ChangeDetectorRefMock();
    service = new AttachmentFileBrowserServiceMock();
    service.getDirectoryFolders.mockReturnValue(of({}));
    modal = new ModalServiceMock();
    attachmentService = new AttachmentServiceMock();
    component = new AttachmentFileBrowserComponent(bsModalRef, cdr, service as any, modal, attachmentService);
    component.hasSettings = true;
    component.filePathControl = {} as any;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should create correct gridOptions', () => {
    component.ngOnInit();
    expect(component.gridOptions).toBeDefined();
    expect(component.gridOptions.columns).toEqual([
      {
        title: 'caseview.attachments.maintenance.fileBrowser.name',
        field: 'pathShortName',
        width: 100,
        sortable: false
      },
      {
        title: 'caseview.attachments.maintenance.fileBrowser.dateModified',
        field: 'dateModified',
        defaultColumnTemplate: DefaultColumnTemplateType.date,
        width: 100,
        sortable: false
      }, {
        title: 'caseview.attachments.maintenance.fileBrowser.type',
        field: 'type',
        width: 100,
        sortable: false
      }, {
        title: 'caseview.attachments.maintenance.fileBrowser.size',
        field: 'size',
        width: 100,
        sortable: false
      }]);
  });

  it('should set select keys properly', () => {
    component.filePathControl = { value: 'c:\\directory\\file.txt' } as any;
    component.ngOnInit();
    expect(component.gridOptions).toBeDefined();
    expect(component.selectedKeys).toEqual(['c:\\directory\\']);
    expect(component.expandedKeys).toEqual(['c:\\', 'c:\\directory\\']);
  });

  it('should handle folder selection correctly', () => {
    component.ngOnInit();
    const node = {
      dataItem: {
        hasFolders: true,
        folders: null,
        fullPath: 'c:theFullPath'
      }
    };
    service.getDirectoryFolders.mockReturnValue(of({ folders: [{ pathShortName: 'name', fullPath: 'c:fullpath' }] }));
    attachmentService.getStorageLocation.mockReturnValue(of({
      allowedFileExtensions: 'doc,docx,pdf', canUpload: true, name: 'name', path: 'c:\\file'
    }));
    component.gridOptions._search = jest.fn();
    component.handleSelection(node);
    expect(component.gridOptions._search).toHaveBeenCalled();
    expect(node.dataItem.folders).toBeDefined();
  });
  it('should assign filepath on row selection', () => {
    component.ngOnInit();
    component.onRowSelectionChanged({ fullPath: 'c:filename', pathShortName: 'filename' });
    expect(component.selectedFile).toEqual('filename');
    expect(component.selectedFileFullPath).toEqual('c:filename');
  });
});
