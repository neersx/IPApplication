import { fakeAsync, flushMicrotasks, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { UpdateNarrativeComponent } from './update-narrative.component';

describe('UpdateNarrativeComponent', () => {
  let ipxNotificationService: IpxNotificationServiceMock;
  let selfModalRef: BsModalRefMock;
  let formBuilder: FormBuilder;
  let cdRef: any;
  const destroy$ = of();
  let component: UpdateNarrativeComponent;

  beforeEach(() => {
    ipxNotificationService = new IpxNotificationServiceMock();
    selfModalRef = new BsModalRefMock();
    formBuilder = new FormBuilder();
    cdRef = new ChangeDetectorRefMock();
    component = new UpdateNarrativeComponent(ipxNotificationService as any, selfModalRef, formBuilder, destroy$ as any, cdRef);
  });

  describe('component', () => {
    it('component is created', () => {
      expect(component).not.toBeNull();
      expect(component.narrativeExtendQuery).toBeDefined();
    });

    it('hides modal on cancel', () => {
      component.cancel();
      expect(selfModalRef.hide).toHaveBeenCalled();
    });
  });

  describe('form interactions', () => {
    it('should create and initialize formGroup', () => {
      expect(component.formGroup).not.toBeNull();
      expect(component.narrative).not.toBeNull();
      expect(component.narrativeText).not.toBeNull();
    });

    it('should set initial values from defaultNarrative', () => {
      component.defaultNarrative = { narrativeNo: 10, narrativeTitle: 'peppa', narrativeText: 'pig' };
      component.defaultNarrativeText = 'Some other text';

      component.ngAfterViewInit();

      expect(component.narrative.value).not.toBeNull();
      expect(component.narrative.value.key).toEqual(10);
      expect(component.narrative.value.value).toEqual('peppa');
      expect(component.narrative.value.text).toEqual('pig');

      expect(component.narrativeText.value).toEqual('pig');
    });

    it('should set initial values from defaultNarrativeText', () => {
      component.defaultNarrative = { title: 'abcd' };
      component.defaultNarrativeText = 'Some other text';

      component.ngAfterViewInit();

      expect(component.narrative.value).toBeNull();
      expect(component.narrativeText.value).toEqual(component.defaultNarrativeText);
    });

    it('should handle narrative value changes', () => {
      component.defaultNarrative = { title: 'abcd' };
      component.defaultNarrativeText = 'Some other text';
      component.ngAfterViewInit();

      component.narrative.setValue({ key: 100, text: 'ABCD' });

      expect(component.narrativeText.value).toEqual('ABCD');
    });

    it('should handle narrative text value changes', () => {
      component.defaultNarrative = { narrativeNo: 10, narrativeTitle: 'peppa', narrativeText: 'pig' };
      component.defaultNarrativeText = 'Some other text';
      component.ngAfterViewInit();
      expect(component.narrative.value).not.toBeNull();

      component.narrativeText.setValue('new text added!!!');

      expect(component.narrative.value).toBeNull();
    });
  });

  describe('apply changes', () => {
    it('opens a confirmation dialog with new narrative', () => {
      component.ngAfterViewInit();
      ipxNotificationService.modalRef.content = { confirmed$: of(true) };
      const newNarrativeText = 'Rain rain go away!';
      component.narrativeText.setValue(newNarrativeText);

      component.apply();

      expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
      expect(ipxNotificationService.openConfirmationModal.mock.calls[0][1]).toEqual('accounting.time.query.updateNarrativeConfirmation');
      expect(ipxNotificationService.openConfirmationModal.mock.calls[0][5].newNarrativeText).toEqual(newNarrativeText);
    });

    it('emits confirmed event on confirmation acceptance', fakeAsync(() => {
      component.ngAfterViewInit();
      const newNarrative = { key: 100, text: 'Mary had a little lamb', title: 'Little lamb' };
      component.narrative.setValue(newNarrative);
      tick();

      ipxNotificationService.modalRef.content = { confirmed$: of({}).pipe(delay(10)) };
      component.confirmed$.subscribe((val) => {
        expect(val.narrativeNo).toEqual(newNarrative.key);
        expect(val.narrativeText).toEqual(newNarrative.text);
      });

      component.apply();
      expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
      expect(ipxNotificationService.openConfirmationModal.mock.calls[0][5].newNarrativeText).toEqual(newNarrative.text);

      tick(10);
      flushMicrotasks();
    }));
  });
});
