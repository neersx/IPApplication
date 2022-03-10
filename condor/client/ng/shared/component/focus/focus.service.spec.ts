import { fakeAsync, TestBed, tick } from '@angular/core/testing';
import { FocusService } from './focus.service';

describe('FocusService: autoFocus', () => {
    let service: FocusService;
    beforeEach(() => {
        TestBed.configureTestingModule({
            providers: [
                FocusService
            ]
        });
        service = TestBed.get(FocusService);
    });
    it('should exist', () => {
        expect(service).toBeDefined();
    });
    it('should set focus', fakeAsync(() => {
        const divElem = document.createElement('div');
        const inputElem = document.createElement('input');
        inputElem.setAttribute('ipx-autofocus', 'true');
        divElem.appendChild(inputElem);
        service.autoFocus(divElem);
        tick(100);
        expect(document.activeElement === divElem.childNodes[0]).toBe(true);
    }));
});
