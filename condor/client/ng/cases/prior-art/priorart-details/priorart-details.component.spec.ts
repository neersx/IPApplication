import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder, FormControl, NgForm } from '@angular/forms';
import { ChangeDetectorRefMock, DateHelperMock, IpxNotificationServiceMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import * as moment from 'moment';
import { of } from 'rxjs';
import { PriorArtServiceMock } from '../priorart.service.mock';
import { PriorArtDetailsComponent } from './priorart-details.component';

describe('PriorArtDetailsComponent', () => {
    let c: PriorArtDetailsComponent;
    let cdr: ChangeDetectorRefMock;
    let ipxNotificationServiceMock: IpxNotificationServiceMock;
    let localDatePipe: any;
    let stateService: StateServiceMock;
    let dateHelper: DateHelperMock;
    const serviceMock = new PriorArtServiceMock();
    const data: any = {
              id: 1,
              abstract: 'aaa'
          };

    beforeEach(() => {
      cdr = new ChangeDetectorRefMock();
      ipxNotificationServiceMock = new IpxNotificationServiceMock();
      localDatePipe = { transform: jest.fn(d => '10-Dec-2000')};
      stateService = new StateServiceMock();
      dateHelper = new DateHelperMock();
      c = new PriorArtDetailsComponent(serviceMock as any, cdr as any, new FormBuilder(), ipxNotificationServiceMock as any, localDatePipe, stateService as any, dateHelper as any);
      c.ngForm = new NgForm(null, null);
    });

    it('should create and initialise the modal', () => {
      c.ngOnInit();
      expect(c).toBeDefined();
    });

    it('should create and initialise the modal', () => {
      c.details = data;
      c.ngOnInit();
      expect(c.formData).toBeDefined();
      expect(c.formData.abstract).toBe(data.abstract);
    });

    it('should not call save when save button is not available', () => {
      c.details = data;
      c.ngOnInit();
      c.savePriorArt();
      expect(serviceMock.saveInprotechPriorArt$).toHaveBeenCalledTimes(0);
    });

    it('should reset form to original data when the reset button is pressed', () => {
      c.details = data;
      c.ngOnInit();
      c.resetForm = jest.fn();
      c.formData.abstract = 'bbb';
      c.revertForm({dataItem: {}});
      expect(c.formData.abstract).toEqual(data.abstract);
      expect(c.resetForm).toHaveBeenCalled();
    });

    describe('datesChanged', () => {
      it('should compare dates changed and return whether they have changed', () => {
        c.details = data;
        c.ngOnInit();
        c.originalData.applicationDate = null;
        c.formGroup.controls.applicationDate.setValue(new Date());

        expect(c.datesChanged()).toBeTruthy();
      });
    });

    describe('generateDescription', () => {
        const publishDate = new Date(2000, 12, 10);
        it('should concatenate literature details with commas', () => {
            c.details = { name: 'npl-author', title: 'npl-title', publishedDate: publishDate, refDocumentParts: 'npl-doc-parts', publisher: 'npl-publisher', city: 'npl-city', country: 'npl-country', countryName: 'npl-country-name'};
            c.ngOnInit();
            c.ngForm.form.addControl('Description', new FormControl(''));
            c.generateDescription();
            expect(c.formData.description).toBe('npl-author, npl-title, 10-Dec-2000, npl-doc-parts, npl-publisher, npl-city, npl-country-name');
            c.title.setValue('npl-new-title');
            c.generateDescription();
            expect(c.formData.description).toBe('npl-author, npl-new-title, 10-Dec-2000, npl-doc-parts, npl-publisher, npl-city, npl-country-name');
        });
        it('should not start with comma', () => {
            c.details = { name: '', title: ' ', refDocumentParts: null, publishedDate: publishDate, publisher: 'npl-publisher', city: 'npl-city', country: 'npl-country', countryName: 'npl-country-name' };
            c.ngOnInit();
            c.ngForm.form.addControl('Description', new FormControl(''));
            c.generateDescription();
            expect(c.formData.description).toBe('10-Dec-2000, npl-publisher, npl-city, npl-country-name');
        });
        it('should not add comma for blank fields', () => {
            c.details = { description: 'old-description', name: 'npl-author', title: 'npl-title', publisher: 'npl-publisher', country: 'npl-country', countryName: 'npl-country-name' };
            c.ngOnInit();
            c.ngForm.form.addControl('Description', new FormControl('old-description'));
            c.generateDescription();
            expect(c.formData.description).toBe('npl-author, npl-title, npl-publisher, npl-country-name');
        });
    });

    describe('initialising', () => {
        const incomingData = {
            country: 'AJK',
            countryCode: 'B2K',
            countryName: 'ABC-XYZ 123'

        };
        beforeEach(() => {
            c.details = incomingData;
            c.ngOnInit();
        });
        it('should initialise the form with correct data', () => {
            expect(c.formData).toEqual(incomingData);
            expect(c.formGroup.controls.country).toBeDefined();
            expect(c.formGroup.controls.country.value).toEqual({
                key: 'B2K',
                value: 'ABC-XYZ 123'});
        });
    });

    describe('Saving', () => {
        const publishDate = new Date(2000, 11, 10);
        beforeEach(() => {
            c.isFormDirty = true;
            c.details = {
                name: 'npl-author',
                title: 'npl-title',
                publishedDate: publishDate,
                refDocumentParts: 'npl-doc-parts',
                publisher: 'npl-publisher',
                city: 'npl-city',
                country: 'npl-country',
                countryName: 'npl-country-name',
                description: '',
                reference: 'ipo-issued-reference',
                kind: 'Dq2N',
                priorityDate: new Date(2000, 11, 11),
                applicationDate: new Date(2000, 11, 12),
                grantedDate: new Date(2000, 11, 13),
                ptoCitedDate: new Date(2000, 11, 14)
            };
            ipxNotificationServiceMock.openConfirmationModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true) } });
            dateHelper.toLocal = (val: Date) => moment(val).format('YYYY-MM-DD');
            c.ngOnInit();
        });
        describe('existing prior art', () => {
            it('persists the updated data', fakeAsync(() => {
                c.formData.id = '123-ABC-xyz';
                c.savePriorArt();
                tick();
                expect(serviceMock.saveInprotechPriorArt$).toHaveBeenCalled();
                expect(serviceMock.saveInprotechPriorArt$.mock.calls[0][0]).toEqual(expect.objectContaining({
                    reference: 'ipo-issued-reference',
                    kind: 'Dq2N',
                    id: '123-ABC-xyz',
                    publishedDate: '2000-12-10',
                    priorityDate: '2000-12-11',
                    applicationDate: '2000-12-12',
                    applicationFiledDate: '2000-12-12',
                    grantedDate: '2000-12-13',
                    ptoCitedDate: '2000-12-14'})
                );
            }));
        });
        describe('new prior art', () => {
            it('saves the data with the correct parameters', fakeAsync(() => {
                c.isLiterature = false;
                c.savePriorArt();
                tick();
                expect(serviceMock.existingPriorArt$).toHaveBeenCalled();
                expect(serviceMock.existingPriorArt$.mock.calls[0][0]).toBe('npl-country');
                expect(serviceMock.existingPriorArt$.mock.calls[0][1]).toBe('ipo-issued-reference');
                expect(serviceMock.existingPriorArt$.mock.calls[0][2]).toBe('Dq2N');
                expect(serviceMock.createInprotechPriorArt$.mock.calls[0][0]).toEqual(expect.objectContaining({ country: 'npl-country', reference: 'ipo-issued-reference', kind: 'Dq2N' }));
            }));
        });
        describe('new literature', () => {
            beforeEach(() => {
                c.isLiterature = true;
            });
            it('saves the data with defaulted description if blank', fakeAsync(() => {
                c.savePriorArt();
                tick();
                expect(serviceMock.existingLiterature$).toHaveBeenCalled();
                expect(serviceMock.existingLiterature$.mock.calls[0][0]).toBeNull();
                expect(serviceMock.createInprotechPriorArt$.mock.calls[1][0]).toEqual(expect.objectContaining({ description: 'npl-author, npl-title, 10-Dec-2000, npl-doc-parts, npl-publisher, npl-city, npl-country-name' }));
            }));
            it('saves the data with provided description', fakeAsync(() => {
                c.ngForm.form.addControl('Description', new FormControl('old-description'));
                c.formData.description = 'npl-description';
                c.savePriorArt();
                tick();
                expect(serviceMock.existingLiterature$).toHaveBeenCalled();
                expect(serviceMock.existingLiterature$.mock.calls[1][0]).toBe('npl-description');
                expect(serviceMock.createInprotechPriorArt$.mock.calls[2][0]).toEqual(expect.objectContaining({description: 'npl-description'}));
            }));
        });
    });
});