import { HttpClientMock } from 'mocks';
import { AttachmentPopupService } from './attachment-popup.service';

describe('Service: Attachment Popup', () => {
    let http: HttpClientMock;
    let service: AttachmentPopupService;

    beforeEach(() => {
        http = new HttpClientMock() as any;
        service = new AttachmentPopupService(http as any);
    });

    describe('hide popups', () => {
        let popup: any;

        beforeEach(() => {
            popup = { hide: jest.fn() };
        });

        it('except current', () => {
            service.hideExcept(popup);
            expect(popup.hide).not.toHaveBeenCalled();

            service.hideExcept(popup);
            expect(popup.hide).not.toHaveBeenCalled();
        });

        it('others', () => {

            service.hideExcept(popup);
            expect(popup.hide).not.toHaveBeenCalled();

            const popup2: any = { hide: jest.fn() };

            service.hideExcept(popup2);
            expect(popup.hide).toHaveBeenCalled();
        });
    });

    it('caches records', () => {
        const ser = (eventNo, eventCycle, fn) => {
            service.getAttachments$(1, eventNo, eventCycle)
                .subscribe(x => {
                    fn();
                });
        };

        ser(1, 1, () => expect(http.get).toHaveBeenCalled());
        ser(1, 1, () => expect(http.get).not.toHaveBeenCalled());

        ser(2, 1, () => expect(http.get).toHaveBeenCalled());
        ser(2, 1, () => expect(http.get).not.toHaveBeenCalled());
        ser(2, 2, () => expect(http.get).toHaveBeenCalled());

        ser(1, 1, () => expect(http.get).not.toHaveBeenCalled());
        ser(2, 2, () => expect(http.get).not.toHaveBeenCalled());

        service.clearCache();
        ser(1, 1, () => expect(http.get).toHaveBeenCalled());
    });
});