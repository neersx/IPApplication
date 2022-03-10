import { HttpClient } from '@angular/common/http';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs/internal/observable/of';
import { IpxTypeaheadService } from './ipx-typeahead.service';

describe('IpxTypeaheadService: getApiData', () => {

    let service: IpxTypeaheadService;
    let httpTestingController: HttpTestingController;
    let httpClientSpy: any;

    beforeEach(() => {
        httpClientSpy = { get: jest.fn(), post: jest.fn() };
        TestBed.configureTestingModule({
            imports: [HttpClientTestingModule],
            providers: [
                IpxTypeaheadService,
                { provide: HttpClient, useValue: httpClientSpy }
            ]
        });

        service = TestBed.get(IpxTypeaheadService);
        httpTestingController = TestBed.get(HttpTestingController);
    });

    afterEach(() => {
        // After every test, assert that there are no more pending requests.
        httpTestingController.verify();
    });

    it('should retrun correct data for jurisdiction', () => {
        const optionsResponse = {
            key: 'MAT',
            code: 'MAT',
            value: 'Madrid Agreement & Protocol (TM)',
            isGroup: true,
            selected: true
        };
        const param = {
            search: 'Madrid'
        };
        const response = {
            key: 'MAT',
            code: 'MAT',
            value: 'Madrid Agreement & Protocol (TM)',
            isGroup: true,
            selected: true
        };

        httpClientSpy.get.mockReturnValue(of(response));

        service.getApiData('api/picklists/jurisdictions', param).subscribe(
            options => {
                expect(options).toEqual(optionsResponse);
            }
        );
    });

    it('should retrun empty result', () => {
        const optionsResponse = {
        };
        const param = {
            search: 'abc'
        };
        const response = {
        };

        httpClientSpy.get.mockReturnValue(of(response));

        service.getApiData('api/picklists/jurisdictions', param).subscribe(
            options => {
                expect(options).toEqual(optionsResponse);
            }
        );
    });
});
