import { of } from 'rxjs';
import { AttachmentFileBrowserService } from './attachment-file-browser.service';

describe('Service: AttachmentFileBrowser', () => {

  const http = { get: jest.fn(), put: jest.fn(), request: jest.fn() };
  it('should create an instance', () => {
    const service = new AttachmentFileBrowserService(http as any);
    expect(service).toBeTruthy();
  });

  it('should call get folders', () => {
    http.get.mockReturnValue(of(null));
    const service = new AttachmentFileBrowserService(http as any);
    service.getDirectoryFolders('c:\\test');

    expect(http.get).toHaveBeenCalledWith('api/attachment/directory', { params: { path: 'c:\\test' } });
  });
  it('should call get files', () => {
    http.get.mockReturnValue(of(null));
    const service = new AttachmentFileBrowserService(http as any);
    service.getDirectoryFiles('c:\\test');

    expect(http.get).toHaveBeenCalledWith('api/attachment/files', { params: { path: 'c:\\test' } });
  });
});
