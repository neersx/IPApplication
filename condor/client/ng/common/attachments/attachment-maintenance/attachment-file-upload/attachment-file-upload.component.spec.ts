import { BsModalRefMock, ChangeDetectorRefMock, Renderer2Mock } from 'mocks';
import { AttachmentFileUploadComponent } from './attachment-file-upload.component';

describe('AttachmentFileUploadComponent', () => {
  let component: AttachmentFileUploadComponent;
  let cdr: any;
  let bsModalRef: any;
  let renderer: any;
  const path = 'c:\\TextPath';
  const extensions = ['.pdf', '.docx'];

  beforeEach(() => {
    bsModalRef = new BsModalRefMock();
    cdr = new ChangeDetectorRefMock();
    renderer = new Renderer2Mock();
    component = new AttachmentFileUploadComponent(bsModalRef, cdr, renderer);
    component.extensions = extensions;
    component.path = path;
  });

  it('should Init correctly', () => {
    expect(component).toBeTruthy();
    component.ngOnInit();
    expect(component.fileRestrictions).toEqual({ allowedExtensions: extensions, maxFileSize: 4194304 });
  });

  it('should upload correctly', () => {
    expect(component).toBeTruthy();
    component.ngOnInit();

    const ev = { data: null };
    component.onUpload(ev as any);
    expect(ev.data).toEqual({ folderPath: path });
  });

  it('should complete Correctly', () => {
    expect(component).toBeTruthy();
    component.ngOnInit();

    component.onComplete();
    expect(component.fileUploaded).toBeTruthy();
  });

  it('should calculateFileSizeCorrectly', () => {
    expect(component).toBeTruthy();
    component.ngOnInit();

    component.onClearButtonClick({ clearFiles: jest.fn() } as any);
    expect(component.pendingFileCount).toEqual(0);

    component.onSelectEvent({
      files: [
        { name: 'fileA', validationErrors: [{ error: true }] },
        { name: 'fileB' }
      ]
    } as any);
    expect(component.pendingFileCount).toEqual(1);

    component.onRemoveEvent({ files: [{ state: 2 }] } as any);
    expect(component.pendingFileCount).toEqual(0);
  });

  it('should calculateFileSizeCorrectly', () => {
    expect(component).toBeTruthy();
    component.ngOnInit();

    component.onSelectEvent({
      files: [
        { name: 'fileA', validationErrors: [{ error: true }] },
        { name: 'fileB' }
      ]
    } as any);
    expect(component.pendingFileCount).toEqual(1);

    component.onUploadEvent();
    expect(component.pendingFileCount).toEqual(0);
  });

});
