import { fakeAsync, tick } from '@angular/core/testing';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { AttachmentMaintenanceComponent } from './attachment-maintenance.component';

describe('AttachmentMaintenanceComponent', () => {
  let component: AttachmentMaintenanceComponent;
  let cdr: any;
  let shortcutsService: any;
  let destroy$: any;
  let rootscopeService: RootScopeServiceMock;
  let bsModalRef: any;

  beforeEach(() => {
    cdr = new ChangeDetectorRefMock();
    shortcutsService = new IpxShortcutsServiceMock();
    destroy$ = of().pipe(delay(1000));
    rootscopeService = new RootScopeServiceMock();
    bsModalRef = new BsModalRefMock();
    component = new AttachmentMaintenanceComponent(cdr, destroy$, shortcutsService, rootscopeService as any, bsModalRef);
    component.maintenanceForm = {
      revert: jest.fn(),
      deleteAttachment: jest.fn(),
      save: jest.fn()
    } as any;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
    component.viewData = { id: 123, baseType: 'case', hasAttachmentSettings: true };
    component.ngOnInit();
    expect(component.id).toEqual(123);
    expect(component.baseType).toEqual('case');
    expect(component.hasSettings).toEqual(true);
    expect(component.isAdding).toEqual(true);
  });

  it('should set correct baseType for case', () => {
    expect(component).toBeTruthy();
    component.viewData = { id: null, baseType: 'activity', hasAttachmentSettings: true };
    component.activityDetails = { activityCaseId: 234 };
    component.ngOnInit();
    expect(component.id).toEqual(234);
    expect(component.baseType).toEqual('case');
    expect(component.hasSettings).toEqual(true);
    expect(component.isAdding).toEqual(true);
  });

  it('should set correct baseType for names', () => {
    expect(component).toBeTruthy();
    component.viewData = { id: null, baseType: 'activity', hasAttachmentSettings: true };
    component.activityDetails = { activityNameId: 345 };
    component.ngOnInit();
    expect(component.id).toEqual(345);
    expect(component.baseType).toEqual('name');
    expect(component.hasSettings).toEqual(true);
    expect(component.isAdding).toEqual(true);
  });

    it('should set correct baseType for prior art', () => {
        expect(component).toBeTruthy();
        component.viewData = { id: null, baseType: 'activity', hasAttachmentSettings: true, priorArtId: -555 };
        component.activityDetails = { id: 999 };
        component.ngOnInit();
        expect(component.id).toEqual(-555);
        expect(component.baseType).toEqual('priorArt');
        expect(component.hasSettings).toEqual(true);
        expect(component.isAdding).toEqual(true);
    });

  it('should subscribe changes correctly', () => {
    component.subscribeChanges(true);
    expect(component.hasValidChanges$.getValue()).toBeTruthy();
    component.subscribeChanges(false);
    expect(component.hasValidChanges$.getValue()).toBeFalsy();
    component.subscribeSavedChanges(true);
    expect(component.hasSavedChanges).toBeTruthy();
  });

  it('should emit saved changes correctly for add another', () => {
    component.subscribeChanges(false);
    expect(component.hasValidChanges$.getValue()).toBeFalsy();
    component.subscribeSavedChanges(true);
    expect(component.hasSavedChanges).toBeTruthy();
  });

  it('should invoke action correctly', () => {
    component.save();
    expect(component.maintenanceForm.save).toHaveBeenCalled();
    component.revert();
    expect(component.maintenanceForm.revert).toHaveBeenCalled();
    component.deleteAttachment();
    expect(component.maintenanceForm.deleteAttachment).toHaveBeenCalled();
  });

  describe('shortcuts', () => {
    beforeEach(() => {
      component.viewData = { id: null, baseType: 'activity', hasAttachmentSettings: true };
      component.activityDetails = { activityNameId: 345 };
    });

    it('calls to initialize shortcut keys on init', () => {
      component.ngOnInit();
      expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT]);
    });

    it('does not call function on save, if form invalid', fakeAsync(() => {
      component.hasValidChanges$.next(false);
      shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;

      component.ngOnInit();
      tick(shortcutsService.interval);
      expect(component.maintenanceForm.save).not.toHaveBeenCalled();
    }));

    it('does not call function on save, if form has no changes', fakeAsync(() => {
      component.hasValidChanges$.next(null);
      shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;

      component.ngOnInit();
      tick(shortcutsService.interval);
      expect(component.maintenanceForm.save).not.toHaveBeenCalled();
    }));

    it('calls function on save, if form is valid and has changes', fakeAsync(() => {
      component.hasValidChanges$.next(true);
      shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;

      component.ngOnInit();
      tick(shortcutsService.interval);
      expect(component.maintenanceForm.save).toHaveBeenCalled();
    }));

    it('does not call function on revert, if form is not changed', fakeAsync(() => {
      component.hasValidChanges$.next(null);
      shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;

      component.ngOnInit();
      tick(shortcutsService.interval);
      expect(component.maintenanceForm.revert).not.toHaveBeenCalled();
    }));

    it('calls function on revert, if form has changes', fakeAsync(() => {
      component.hasValidChanges$.next(false);
      shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;

      component.ngOnInit();
      tick(shortcutsService.interval);
      expect(component.maintenanceForm.revert).toHaveBeenCalled();
    }));

    it('calls function on revert, if form has changes', fakeAsync(() => {
      component.ngOnInit();
      component.close(null);
      expect(bsModalRef.hide).toHaveBeenCalled();
    }));
  });
});
