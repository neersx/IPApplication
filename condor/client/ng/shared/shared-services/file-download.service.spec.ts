import { HttpClientMock } from 'mocks';
import { FileDownloadService } from './file-download.service';

describe('Service: FileDownload', () => {
  let service: FileDownloadService;
  const httpMock = new HttpClientMock();

  beforeEach(() => {
    service = new FileDownloadService(httpMock as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  it('should call the exportToExcel method', (() => {
    const url = 'http://someurl.com';
    const body = { a: 'a' };

    httpMock.post = jest.fn((u, b, p) => {
      expect(u).toBe(url);
      expect(b).toBe(body);
      expect(p.observe).toBe('response');
      expect(p.responseType).toBe('arraybuffer');

      return {
        subscribe: (response: any) => {
          expect(response).toBeDefined();
        }
      };
    });

    service.downloadFile(url, body as any);

    expect(httpMock.post).toHaveBeenCalled();
  }));
});
