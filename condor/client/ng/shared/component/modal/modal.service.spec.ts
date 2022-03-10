import { BsModalServiceMock } from 'mocks/bs-modal.service.mock';
import { KeyBoardShortCutServiceMock } from 'mocks/keyboardshortcutservice.mock';
import { ModalOptions } from 'ngx-bootstrap/modal';
import { IpxModalService } from 'shared/component/modal/modal.service';

describe('Service: ModalService', () => {
  let bsModalServiceMock: BsModalServiceMock;
  let keyBoardShortCutServiceMock: KeyBoardShortCutServiceMock;
  let service: IpxModalService;

  beforeEach(() => {
    bsModalServiceMock = new BsModalServiceMock();
    keyBoardShortCutServiceMock = new KeyBoardShortCutServiceMock();
    service = new IpxModalService(bsModalServiceMock as any, keyBoardShortCutServiceMock as any);
  });

it('should create an instance', () => {
        expect(service).toBeTruthy();
  });

  describe('show bootstrap modal', () => {
    it('should call to show the modal with the correct values', () => {
        const content = '<h1>Modal Content<h1>';
        const modalOptions: ModalOptions = {
            class: 'abc',
            animated: true,
            backdrop: true
        };

        service.openModal(content, modalOptions);
        expect(bsModalServiceMock.show).toHaveBeenCalledWith(expect.stringContaining(content), expect.objectContaining(modalOptions));
    });
  });
});
