import { Observable } from 'rxjs';

export class ChangePasswordServiceMock {
    updateUserPassword = jest.fn().mockReturnValue(new Observable());
}