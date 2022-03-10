import { of } from 'rxjs';

export class AttachmentModalServiceMock {
  viewData$ = of(this.viewData);
  displayAttachmentModal = jest.fn();
  triggerAddAttachment = jest.fn();
  attachmentsModified = of({});

  constructor(private readonly viewData: any = {}) {
  }
}