import { FormBuilder, NgForm } from '@angular/forms';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, StateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { IpoSearchType, PriorArtType } from '../priorart-model';
import { PriorArtServiceMock, PriorArtShortcutsMock } from '../priorart.service.mock';
import { PriorartSearchResultComponent } from '../search-result/priorart-search-result.component';
import { IpoSearch, PriorArtSearch, PriorArtSearchResult } from './priorart-search-model';
import { PriorArtSearchComponent } from './priorart-search.component';

describe('PriorArtSearchComponent', () => {
    let component: PriorArtSearchComponent;
    let service: PriorArtServiceMock;
    let notifictionService: IpxNotificationServiceMock;
    let stateService: any;
    let cdRef = new ChangeDetectorRefMock();
    let shortcuts = new PriorArtShortcutsMock();

    let data: any = {
        result: [{
            errors: false,
            matches: {
                data: [{
                    id: 1
                },
                {
                    id: 2
                }]
            },
            message: 'aaa',
            source: 'IpOneDataDocumentFinder'
        },
        {
            errors: false,
            matches: {
                data: [{
                    id: 1
                }]
            },
            message: 'bbb',
            source: 'CaseEvidenceFinder'
        },
        {
            errors: false,
            matches: {
                data: [{
                    id: 1
                },
                {
                    id: 2
                },
                {
                    id: 3
                }]
            },
            message: 'ccc',
            source: 'ExistingPriorArtFinder'
        }]
    };

    beforeEach(() => {
        service = new PriorArtServiceMock();
        cdRef = new ChangeDetectorRefMock();
        stateService = new StateServiceMock();
        notifictionService = new IpxNotificationServiceMock();
        shortcuts = new PriorArtShortcutsMock();

        stateService.params.caseKey = -111;
        stateService.params.sourceId = -22;

        service.getSearchedData$ = jest.fn().mockReturnValue(of(data));
        component = new PriorArtSearchComponent(service as any, cdRef as any, stateService, notifictionService as any, shortcuts as any, new FormBuilder());
        component.ngForm = new NgForm(null, null);
    });

    it('should create the component', (() => {
        expect(component).toBeTruthy();
    }));

    it('should initialise the context', (() => {
        component.ngOnInit();

        expect(component.sourceId).toBe(stateService.params.sourceId);
        expect(component.caseKey).toBe(stateService.params.caseKey);
    }));

    it('should set form value to source if not isSourceDocument', () => {
        component.isSourceDocument = false;
        component.sourceId = 1;

        component.ngOnInit();

        expect(component.formGroup.value.selectedPriorArtType).toEqual(PriorArtType.Source);
    });

    it('should set form value to Ipo if isSourceDocument', () => {
        component.isSourceDocument = true;
        component.sourceId = 1;

        component.ngOnInit();

        expect(component.formGroup.value.selectedPriorArtType).toEqual(PriorArtType.Ipo);
    });

    it('should set the searched data for valid searches', (() => {
        component.ngOnInit();
        component.validateIpoSearchItems = jest.fn().mockReturnValue(true);
        component.isLoaded = false;
        component.priorArtNotFound = jest.fn().mockReturnValue(of(new Array<PriorArtSearchResult>()));
        component.formGroup = new FormBuilder().group({
            applicationNo: '86jnmv   ',
            kindCode: 'kind c  ',
            jurisdiction: { code: '', value: '' }
        });
        component.search();

        expect(service.getSearchedData$).toHaveBeenCalled();
        expect(component.ipOneData).not.toBe(null);
        expect(component.inprotechData).not.toBe(null);
        expect(component.combinedData).not.toBe(null);
        expect(component.caseReferenceData).not.toBe(null);
        expect(component.ipOneData.length).toBe(2);
        expect(component.inprotechData.length).toBe(3);
        expect(component.combinedData.length).toBe(5);
        expect(component.isLoaded).toBe(true);
    }));

    it('should set the searched data', (() => {
        component.ngOnInit();
        component.validateIpoSearchItems = jest.fn().mockReturnValue(true);
        component.isLoaded = false;
        component.hasIpd1Error = false;
        data = {
            result: [{
                errors: true,
                matches: {
                    data: []
                },
                message: 'error',
                source: 'IpOneDataDocumentFinder'
            },
            {
                errors: false,
                matches: {
                    data: [{
                        id: 1
                    }]
                },
                message: 'bbb',
                source: 'CaseEvidenceFinder'
            },
            {
                errors: false,
                matches: {
                    data: [{
                        id: 1
                    },
                    {
                        id: 2
                    },
                    {
                        id: 3
                    }]
                },
                message: 'ccc',
                source: 'ExistingPriorArtFinder'
            }]
        };
        service.getSearchedData$ = jest.fn().mockReturnValue(of(data));
        component.priorArtNotFound = jest.fn().mockReturnValue(of(new Array<PriorArtSearchResult>()));
        component.formGroup = new FormBuilder().group({
            applicationNo: '86jnmv   ',
            kindCode: 'kind c  ',
            jurisdiction: { code: '', value: '' }
        });

        component.search();

        expect(service.getSearchedData$).toHaveBeenCalled();
        expect(component.ipOneData).toEqual([]);
        expect(component.inprotechData.length).toBe(3);
        expect(component.combinedData.length).toBe(3);
        expect(component.caseReferenceData.length).toBe(1);
        expect(component.isLoaded).toBe(true);
        expect(component.hasIpd1Error).toBe(true);
    }));

    it('should clear the set data', (() => {
        component.ngOnInit();
        component.formGroup.controls.applicationNo.setValue('123');
        component.formGroup.controls.kindCode.setValue('a');
        component.ipOneData = [{
            id: '',
            reference: '',
            citation: '',
            title: '',
            name: '',
            kind: '',
            abstract: '',
            description: '',
            comments: '',
            refDocumentParts: '',
            publisher: '',
            city: ''
        }];
        component.inprotechData = [{
            id: '',
            reference: '',
            citation: '',
            title: '',
            name: '',
            kind: '',
            abstract: '',
            description: '',
            comments: '',
            refDocumentParts: '',
            publisher: '',
            city: ''
        }];
        component.combinedData = [{
            id: '',
            reference: '',
            citation: '',
            title: '',
            name: '',
            kind: '',
            abstract: '',
            description: '',
            comments: '',
            refDocumentParts: '',
            publisher: '',
            city: ''
        }];
        component.clear();
        expect(component.ipOneData.length).toBe(0);
        expect(component.inprotechData.length).toBe(0);
        expect(component.combinedData.length).toBe(0);
        expect(component.formGroup.value.applicationNo).toBeNull();
        expect(component.formGroup.value.kindCode).toBeNull();
    }));

    it('should return not found data when no matches have been found', (() => {
        const request = new PriorArtSearch();
        request.countryName = 'AU';
        request.officialNumber = '12345';
        component.combinedData = [];
        component.caseReferenceData = [];
        const notFoundData = component.priorArtNotFound(request);

        expect(notFoundData.length).toEqual(1);
        expect(notFoundData[0].countryName).toEqual(request.countryName);
        expect(notFoundData[0].reference).toEqual(request.officialNumber);
    }));

    it('should return not found data when no matches have been found during a multi search', (() => {
        const request = new PriorArtSearch();
        const firstSearch = new IpoSearch();
        firstSearch.country = 'AU';
        firstSearch.officialNumber = '1123';
        const secondSearch = new IpoSearch();
        secondSearch.country = 'CN';
        secondSearch.officialNumber = '112333455';
        secondSearch.kind = 'B';
        component.combinedData = [];
        component.caseReferenceData = [];
        request.multipleIpoSearch = [firstSearch, secondSearch];
        const notFoundData = component.priorArtNotFoundMultiple(request);

        expect(notFoundData.length).toEqual(2);
        expect(notFoundData[0].reference).toEqual(firstSearch.officialNumber);
        expect(notFoundData[1].reference).toEqual(secondSearch.officialNumber);
    }));

    describe('onRefresh', () => {
        it('should refresh the data', () => {
          const event = {
            success: true,
            importedRef: 'IPO'
          };
          const priorArtSearchResult = new PriorartSearchResultComponent({ } as any, { } as any, { } as any, { } as any, { } as any);
          priorArtSearchResult.expandFirstRowOnRefresh = false;
          component.getGridData = jest.fn();
          component.priorartSearchResult = priorArtSearchResult;
          component.onRefresh(event);

          expect(component.getGridData).toHaveBeenCalledWith(event.importedRef);
          expect(component.priorartSearchResult.expandFirstRowOnRefresh).toBeTruthy();
        });
    });

    describe('disableSearch', () => {
        it('should enable search button for IPO search when mandatory search fields are entered', () => {
            component.ngOnInit();
            component.toggleSourceType(PriorArtType.Ipo);
            component.formGroup.controls.applicationNo.setValue('123');
            component.formGroup.controls.jurisdiction.setValue({ code: 'AU', value: 'aussie' });

            expect(component.disableSearch()).toBeFalsy();
        });
        it('should disable search button for IPO search when mandatory search fields are not entered', () => {
            component.ngOnInit();
            component.toggleSourceType(PriorArtType.Ipo);

            expect(component.disableSearch()).toBeTruthy();
        });
        it('should always enable search button for non IPO search', () => {
            component.ngOnInit();
            component.toggleSourceType(PriorArtType.Literature);

            expect(component.disableSearch()).toBeFalsy();
        });
        it('should disable search if doing an empty multi search and enable after text entered', () => {
            component.ngOnInit();
            component.toggleSourceType(PriorArtType.Ipo);
            component.setSelectedIpoSearch(IpoSearchType.Multiple);

            expect(component.disableSearch()).toBeTruthy();

            component.formGroup.controls.multipleIpoText.setValue('AU-694843-A');
            expect(component.disableSearch()).toBeFalsy();

            component.formGroup.controls.multipleIpoText.setValue('US-12300,US-12301,US-12302,US-12303,US-12304,US-12305,US-12306,US-12307,US-12308,US-12309,US-12310,US-12311,US-12312,US-12313,US-12314,US-12315,US-12316,US-12317,US-12318,US-12319,US-12320');
            expect(component.disableSearch()).toBeFalsy();
        });
    });

    describe('validateIpoSearchItems', () => {
        it('should invalid if search string is not valid', () => {
            component.ngOnInit();
            component.formGroup.controls.multipleIpoText.setValue('AU-');

            expect(component.validateIpoSearchItems()).toBeFalsy();
        });
    });

    describe('parseMultiSearchText', () => {
        it('should correctly tokenise the entered multi search text', () => {
          component.ngOnInit();
          const query = 'AU-69423-DA;AU-6943843-A;AU-33-A';
          const result = component.parseMultiSearchText(query);

          expect(result.length).toEqual(3);
          expect(result[0].country).toEqual('AU');
          expect(result[0].officialNumber).toEqual('69423');
          expect(result[2].kind).toEqual('A');
        });
        it('should not include search items that are not valid', () => {
            component.ngOnInit();
            const valid = 'AU-6943843-A;AU-33-A';
            const invalid = 'US202012356 A1';
            const query = valid + ',' + invalid;
            const result = component.parseMultiSearchText(query);

            expect(result.length).toEqual(2);
            expect(result[0].country).toEqual('AU');
            expect(result[1].officialNumber).toEqual('33');
        });
        it('should allow different separators and delimiters', () => {
            component.ngOnInit();
            const query = 'AU 777777 A1,AU 777777 A1,US 989898\nWO 201234567 A2;JP 88123456 B2;777777-A1;12341234,ep 100123-b1\r\nus 20000909';
            const result = component.parseMultiSearchText(query);

            expect(result[0].country).toEqual('AU');
            expect(result[0].officialNumber).toEqual('777777');
            expect(result[0].kind).toEqual('A1');
            expect(result[1].country).toEqual('US');
            expect(result[1].officialNumber).toEqual('989898');
            expect(result[1].kind).toBeNull();
            expect(result[2].country).toEqual('WO');
            expect(result[2].officialNumber).toEqual('201234567');
            expect(result[2].kind).toBe('A2');
            expect(result[3].country).toEqual('JP');
            expect(result[3].officialNumber).toEqual('88123456');
            expect(result[3].kind).toBe('B2');
            expect(result[4].country).toEqual('EP');
            expect(result[4].officialNumber).toEqual('100123');
            expect(result[4].kind).toBe('B1');
            expect(result[5].country).toEqual('US');
            expect(result[5].officialNumber).toEqual('20000909');
            expect(result[5].kind).toBeNull();
        });
    });

    describe('multiTextEnter', () => {
        it('should prevent the enter click if multi text is invalid', () => {
            const event = { preventDefault: jest.fn() };
            component.ngOnInit();
            component.validateIpoSearchItems = jest.fn().mockReturnValue(false);
            component.multiTextEnter(event);

            expect(event.preventDefault).toHaveBeenCalled();
        });

        it('should not prevent the enter click if multi text is valid', () => {
            const event = { preventDefault: jest.fn() };
            component.ngOnInit();
            component.validateIpoSearchItems = jest.fn().mockReturnValue(true);
            component.multiTextEnter(event);

            expect(event.preventDefault).toHaveBeenCalledTimes(0);
        });

        it('should not validate if not an ipo multi-text search', () => {
            component.ngOnInit();
            component.validateIpoSearchItems = jest.fn();
            component.search();

            expect(component.validateIpoSearchItems).not.toHaveBeenCalled();
        });
    });
});