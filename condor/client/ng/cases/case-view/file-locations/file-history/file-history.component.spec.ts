import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { FileHistoryComponent } from './file-history.component';

describe('FileHistoryComponent', () => {
  let component: FileHistoryComponent;
  let modalServiceMock: ModalServiceMock;
  const topic: Topic = {
    key: '',
    title: '',
    params: {
      viewData: {
        irn: 123
      }
    }
  };
  beforeEach(() => {
    modalServiceMock = new ModalServiceMock();
    component = new FileHistoryComponent(modalServiceMock as any);
    component.topic = topic;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('initialize component', () => {
    component.ngOnInit();
    expect(component.irn).toBe(topic.params.viewData.irn);
  });
  it('close history modal', () => {
    jest.spyOn(modalServiceMock.modalRef, 'hide');
    component.cancel();
    expect(modalServiceMock.modalRef.hide).toBeCalled();
  });
});
