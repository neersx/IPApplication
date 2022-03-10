import { Observable } from 'rxjs';

export class ResetPasswordServiceMock {
    sendEmail = jest.fn().mockReturnValue(new Observable());
    updatePassword = jest.fn().mockReturnValue(new Observable());
}

export class ActivatedRouteMock {
    queryParamMap = { subscribe: jest.fn().mockReturnValue(new Observable()) };
}

export class AuthenticationServiceMock {
    getOptions = jest.fn(() => { return {
        then: jest.fn(() => { return { then: jest.fn() }; })
    }; });
}

export class ChangeDetectorRefMock {
    detectChanges = jest.fn();
    markForCheck = jest.fn();
}

export class RouterMock {
    navigateByUrl = jest.fn();
}

export class TranslateServiceMock {
    addLangs = jest.fn();
    setDefaultLang = jest.fn();
    setTranslation = jest.fn();
    use = jest.fn();
    get = jest.fn().mockReturnValue(new Observable());
}
