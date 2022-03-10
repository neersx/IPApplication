import { TopicsExampleComponent } from 'dev/ipx-topics/topics-example.component';
import { ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { AttachmentPopupServiceMock } from './attachment-popup.service.mock';
import { AttachmentsPopupComponent } from './attachments-popup.component';

describe('Attachment Popup Component', () => {
    let component: AttachmentsPopupComponent;
    let service: AttachmentPopupServiceMock;
    let cdr: ChangeDetectorRefMock;
    let ipxDestroy: IpxDestroy;

    beforeEach(() => {
        service = new AttachmentPopupServiceMock();
        cdr = new ChangeDetectorRefMock();
        ipxDestroy = of({}) as any;
        component = new AttachmentsPopupComponent(service as any, cdr as any, ipxDestroy);
        component.popover = {} as any;
    });

    it('click should hide popups', () => {
        expect(component).toBeTruthy();

        component.onClick();
        expect(service.hideExcept).toHaveBeenCalledWith(undefined);
    });

    it('on shown', () => {
        component.caseKey = 100;
        component.eventNo = 99;
        component.eventCycle = 6;

        expect(component.isLoading).toBeFalsy();

        component.onShown();
        expect(component.isLoading).toBeTruthy();
        expect(service.hideExcept).toHaveBeenCalled();
        expect(service.getAttachments$).toHaveBeenCalledWith(component.caseKey, component.eventNo, component.eventCycle);
    });

    it('sets flag dataRetrivable correctly', () => {
        component.ngOnInit();
        expect(component.dataRetrivable).toBeFalsy();

        component.caseKey = 10;
        component.ngOnInit();
        expect(component.dataRetrivable).toBeFalsy();

        component.eventNo = 100;
        component.ngOnInit();
        expect(component.dataRetrivable).toBeFalsy();

        component.eventCycle = undefined;
        component.ngOnInit();
        expect(component.dataRetrivable).toBeFalsy();

        component.eventCycle = 1;
        component.ngOnInit();
        expect(component.dataRetrivable).toBeTruthy();
    });
});