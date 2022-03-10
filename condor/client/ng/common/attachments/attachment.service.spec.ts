import { of } from 'rxjs/internal/observable/of';
import { AttachmentService } from './attachment.service';

describe('Service: Attachment', () => {
  const http = { get: jest.fn(), put: jest.fn(), request: jest.fn() };

  it('should create an instance', () => {
    const service = new AttachmentService(http as any);
    expect(service).toBeTruthy();
  });

  describe('getAttachments', () => {
    it('should call the getAttachment api with the correct parameters', () => {
      http.get.mockReturnValue(of(null));
      const service = new AttachmentService(http as any);
      const queryParam = { take: 0, skip: 0 };
      service.getAttachments$('case', 123, queryParam);

      expect(http.get).toHaveBeenCalledWith('api/case/123/attachments', { params: { params: JSON.stringify(queryParam) } });
    });

    it('should call the getAttachment api with the correct prior art parameters', () => {
      http.get.mockReturnValue(of(null));
      const service = new AttachmentService(http as any);
      const queryParam = { take: 0, skip: 0 };
      service.getAttachments$('priorArt', 333, queryParam);

      expect(http.get).toHaveBeenCalledWith('api/priorArt/333/attachments', { params: { params: JSON.stringify(queryParam) } });
    });

    it('should call view with the correct parameters', () => {
      http.get.mockReturnValue(of(null));
      const service = new AttachmentService(http as any);
      service.attachmentMaintenanceView$('case', 123, { eventKey: '999', eventCycle: '2' });

      expect(http.get).toHaveBeenCalledWith('api/attachment/case/view/123', { params: { eventKey: '999', eventCycle: '2' } });
    });

    it('should call validate path with the correct parameters', () => {
      http.get.mockReturnValue(of(null));
      const service = new AttachmentService(http as any);
      service.validatePath$('c:\\test.pdf');

      expect(http.get).toHaveBeenCalledWith('api/attachment/validatePath', { params: { path: 'c:\\test.pdf' } });
      service.validatePath$('').subscribe(v => {
        expect(v).toBeNull();
      });
      service.validatePath$(null).subscribe(v => {
        expect(v).toBeNull();
      });
    });

    it('should call get attachment with the correct parameters', () => {
      http.get.mockReturnValue(of(null));
      const service = new AttachmentService(http as any);
      service.getAttachment$('case', 123, '111', '1');

      expect(http.get).toHaveBeenCalledWith('api/attachment/case/123', { params: { activityId: '111', sequence: '1' } });
    });

    describe('save', () => {
      it('should call update attachment with the correct parameters', () => {
        http.get.mockReturnValue(of(null));
        const service = new AttachmentService(http as any);
        const payload = { activityId: 123, sequenceNo: 123, eventNo: '0001' };
        service.addOrUpdateAttachment$('case', 123, payload);
        expect(http.put).toHaveBeenCalledWith('api/attachment/update/case/123', payload);

        service.addOrUpdateAttachment$('name', 123, payload);
        expect(http.put).toHaveBeenCalledWith('api/attachment/update/name/123', payload);

        service.addOrUpdateAttachment$('case', null, payload);
        expect(http.put).toHaveBeenCalledWith('api/attachment/update/case', payload);

        service.addOrUpdateAttachment$('name', null, payload);
        expect(http.put).toHaveBeenCalledWith('api/attachment/update/name', payload);
      });

      it('should call add attachment with the correct parameters', () => {
        http.get.mockReturnValue(of(null));
        const service = new AttachmentService(http as any);
        const payload = { eventNo: '0001' };
        service.addOrUpdateAttachment$('case', 123, payload);
        expect(http.put).toHaveBeenCalledWith('api/attachment/new/case/123', payload);

        service.addOrUpdateAttachment$('case', null, payload);
        expect(http.put).toHaveBeenCalledWith('api/attachment/new/case', payload);

        service.addOrUpdateAttachment$('name', 5678, payload);
        expect(http.put).toHaveBeenCalledWith('api/attachment/new/name/5678', payload);

        service.addOrUpdateAttachment$('name', null, payload);
        expect(http.put).toHaveBeenCalledWith('api/attachment/new/name', payload);
      });
    });
  });

  describe('delete attachment', () => {
    it('should call api to delete attachment', () => {
      http.request.mockReturnValue(of(true));
      const service = new AttachmentService(http as any);

      const attachment = { attachmentId: 1 };
      service.deleteAttachment('case', 100, attachment, false);

      expect(http.request).toHaveBeenCalled();
      expect(http.request.mock.calls[0][0]).toEqual('delete');
      expect(http.request.mock.calls[0][1]).toEqual('api/attachment/delete/case/100');
      expect(http.request.mock.calls[0][2]).toEqual({ body: attachment });
    });
  });
});
