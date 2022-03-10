import { fakeAsync, tick } from '@angular/core/testing';
import { PriorArtServiceMock } from 'cases/prior-art/priorart.service.mock';
import { BsModalRefMock } from 'mocks';
import { UpdatePriorArtStatusComponent } from './update-priorart-status.component';

describe('UpdatePriorArtStatusComponent', () => {
    let c: UpdatePriorArtStatusComponent;
    let bsModalRef: any;
    let service: any;

    beforeEach(() => {
        bsModalRef = new BsModalRefMock();
        service = new PriorArtServiceMock();
        c = new UpdatePriorArtStatusComponent(bsModalRef, service);
        c.caseKeys = [555, 23, 68];
        c.sourceDocumentId = -777;
        c.priorArtStatus = {key: 1487, value: 'ABC-xyz ABC-xyz'};
        c.isSelectAll = false;
        c.exceptCaseKeys = [];
    });
    it('calls the api correctly to save', fakeAsync(() => {
        c.save();
        expect(service.updatePriorArtStatus$.mock.calls[0][0]).toEqual(expect.objectContaining({
            caseKeys: c.caseKeys,
            sourceDocumentId: c.sourceDocumentId,
            status: 1487,
            isSelectAll: false,
            exceptCaseKeys: []
        }));
        tick();
        expect(bsModalRef.hide).toHaveBeenCalled();
    }));
    it('closes the modal when cancelled', () => {
        c.cancel();
        expect(bsModalRef.hide).toHaveBeenCalled();
    });
});