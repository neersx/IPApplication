import { HttpClient } from '@angular/common/http';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { TranslateService } from '@ngx-translate/core';

// tslint:disable-next-line: import-blacklist
import { of } from 'rxjs';
import { TranslatedServiceMock } from '../mock/translate-service.mock';
import { AuthenticationService } from './authentication.service';

describe('AuthenticationService', () => {
  let httpClientSpy;
  let fixture: AuthenticationService;

  beforeEach(() => {
    httpClientSpy = { get: jest.fn(), post: jest.fn() };
    TestBed.configureTestingModule({
      providers: [{ provide: HttpClient, useValue: httpClientSpy },
      { provide: TranslateService, useValue: TranslatedServiceMock }],
      imports: [HttpClientTestingModule]
    });
  });

  beforeEach(() => {
    fixture = TestBed.get(AuthenticationService);
  });

  it('should retrun correct options', () => {
    const optionsResponse = {
      userAgent: {
        languages: ['en']
      },
      systemInfo: 'systemInfo',
      signInOptions: 'result',
      resource: { en: 'english' }
    };

    const response = {
      userAgent: {
        languages: ''
      },
      systemInfo: 'systemInfo',
      result: 'result',
      __resources: { en: 'english' }
    };

    httpClientSpy.get.mockReturnValue(of(response));

    fixture.getOptions().then(
      options => expect(options).toEqual(optionsResponse)
    );
  });

  it('should retrun signin response', () => {
    const response = {
      status: 'ready'
    };

    httpClientSpy.post.mockReturnValue(of(response));
    fixture.signin('', '', '', '', '', '').then(
      result => expect(result).toEqual(response)
    );
  });
});
