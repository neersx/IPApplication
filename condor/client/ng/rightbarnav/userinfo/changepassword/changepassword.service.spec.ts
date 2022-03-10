import { HttpClientMock } from 'mocks';
import { ChangePasswordService } from './changepassword.service';

describe('ChangePasswordService', () => {
    let service: ChangePasswordService;
    const httpMock = new HttpClientMock();
    beforeEach(() => {
        service = new ChangePasswordService(httpMock as any);
    });

    it('should be created', () => {
        expect(ChangePasswordService).toBeTruthy();
    });

    it('Validate updateUserPassword', () => {
        const request = {};
        service.updateUserPassword(request);
        expect(httpMock.post).toHaveBeenCalled();
    });
});