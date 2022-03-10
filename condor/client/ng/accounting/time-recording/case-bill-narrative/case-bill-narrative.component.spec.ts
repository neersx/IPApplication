import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { NotificationServiceMock } from 'ajs-upgraded-providers/notification-service.mock';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { CaseBillNarrativeComponent } from './case-bill-narrative.component';

describe('CaseBillNarrativeComponent', () => {
    let component: CaseBillNarrativeComponent;
    let service: {
        getCaseNarativeDefaults(caseKey: number): any,
        setCaseBillNarrative(data: any): any,
        getCaseBillNarrative(caseKey: number, language: number): any,
        deleteCaseBillNarrative(data: any): any,
        getAllCaseNarratives(caseKey: number): any
    };
    const notificationRef = {
        content: {
            confirmed$: of({}),
            cancelled$: of({})
        }
    };
    let notificationService: IpxNotificationServiceMock;
    let successNotificationServiceMock: NotificationServiceMock;
    let modalRef: BsModalRefMock;
    let shortcutsService: IpxShortcutsServiceMock;
    let destroy$: any;
    let fb: FormBuilder;
    let cdRef: ChangeDetectorRefMock;
    beforeEach(() => {
        service = {
            getCaseNarativeDefaults: jest.fn().mockReturnValue(of({ result: 'success' })),
            getCaseBillNarrative: jest.fn().mockReturnValue(of('notes')),
            setCaseBillNarrative: jest.fn().mockReturnValue(of({})),
            deleteCaseBillNarrative: jest.fn().mockReturnValue(of({ result: 'success' })),
            getAllCaseNarratives: jest.fn().mockReturnValue(of([{
                selected: true,
                language: { key: 0, value: 'German' }
            }, {
                selected: true,
                language: { key: 1, value: 'French' }
            }]))
        };
        cdRef = new ChangeDetectorRefMock();
        notificationService = new IpxNotificationServiceMock();
        successNotificationServiceMock = new NotificationServiceMock();
        modalRef = new BsModalRefMock();
        shortcutsService = new IpxShortcutsServiceMock();
        destroy$ = of({}).pipe(delay(1000));
        fb = new FormBuilder();
        component = new CaseBillNarrativeComponent(service as any, notificationService as any, modalRef as any, cdRef as any, destroy$, shortcutsService as any, successNotificationServiceMock as any, fb);
        (component as any).sbsModalRef = {
            hide: jest.fn()
        } as any;
        component.onClose$.next = jest.fn() as any;
        component.form = {
            value: {
                renew: true
            },
            invalid: false,
            get: jest.fn().mockReturnValue({}),
            setValue: jest.fn(),
            dirty: true,
            markAsDirty: jest.fn(),
            controls: {
                notes: { value: '', setValue: jest.fn().mockReturnValue('Test'), markAsPristine: jest.fn() },
                language: {
                    value: { key: 2 }, setValue: jest.fn().mockReturnValue({ key: 2 }), markAsPristine: jest.fn()
                }
            }
        };
        component.caseKey = 1;
    });
    it('should create', () => {
        expect(component).toBeTruthy();
    });
    it('should call service getCaseReference', () => {
        component.ngOnInit();
        expect(service.getCaseNarativeDefaults).toHaveBeenCalledWith(component.caseKey);
    });
    it('should initialize shortcuts', () => {
        component.ngOnInit();
        expect(shortcutsService.observeMultiple$).toHaveBeenCalledWith([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT]);
    });
    it('should call save if shortcut is given', fakeAsync(() => {
        component.onSave = jest.fn();
        shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
        component.ngOnInit();
        tick(shortcutsService.interval);
        expect(component.onSave).toHaveBeenCalled();
    }));
    it('should call revert if shortcut is given', fakeAsync(() => {
        component.close = jest.fn();
        shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
        component.ngOnInit();
        tick(shortcutsService.interval);
        expect(component.close).toHaveBeenCalled();
    }));
    it('should call notification success on save', (done) => {
        component.saveDisabled = false;
        component.onSave();
        expect(service.setCaseBillNarrative).toBeCalled();
        const data = {
            language: component.form.controls.language.value && component.form.controls.language.value.key ? component.form.controls.language.value.key : null,
            notes: component.form.controls.notes.value,
            caseKey: component.caseKey
        };
        service.setCaseBillNarrative(data).subscribe(() => {
            expect(successNotificationServiceMock.success).toHaveBeenCalled();
            done();
        });
    });
    it('should call notification on close if save enabled', fakeAsync(() => {
        const model = { content: { confirmed$: of(), cancelled$: of() } };
        notificationService.openDiscardModal.mockReturnValue(model);
        component.close();
        tick(10);
        model.content.confirmed$.subscribe(() => {
            expect(modalRef.hide).toHaveBeenCalled();
            expect(component.onClose$.next).toHaveBeenCalledWith(false);
        });
    }));
    it('should hide modal if close is called', () => {
        component.close();
        expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
        expect(component.onClose$.next).toHaveBeenCalledWith(false);
    });
    describe('goto step in text wizard', () => {
        beforeEach(() => {
            component.ngOnInit();
        });

        it('should goto step and current step should be selected', () => {
            component.steps = [{
                selected: true,
                language: { key: component.steps.length, value: 'German' }
            }];

            const newStep = {
                selected: false,
                language: { key: component.steps.length + 1, value: 'French' }
            };
            component.language.setValue('English');
            component.steps.push(newStep);
            component.goTo(newStep);
            expect(newStep.selected).toBe(true);
        });

        it('should set saveDisabled as true when notes is set', () => {
            component.saveDisabled = false;
            component.setNotes('Current Notes');
            expect(component.saveDisabled).toBeTruthy();
        });

        it('should remove corresponding steps', (done) => {
            notificationService.openDeleteConfirmModal = jest.fn().mockReturnValue(notificationRef);
            component.steps = [{
                selected: true,
                language: { key: component.steps.length, value: 'German' }
            }];
            component.removeStep(component.steps[0]);
            expect(notificationService.openDeleteConfirmModal).toHaveBeenCalledWith('modal.confirmDelete.message');
            notificationRef.content.confirmed$.subscribe(() => {
                expect(component.steps.length).toEqual(0);
                done();
            });
        });
        it('should get step for the given language', (done) => {
            component.steps = [{
                selected: true,
                language: { key: 0, value: 'German' }
            }, {
                selected: true,
                language: { key: 1, value: 'French' },
                notes: 'abc'
            }];
            jest.spyOn(component, 'setNotes');
            jest.spyOn(component, 'goTo');
            component.getSteps(1);
            service.getAllCaseNarratives(1).subscribe(() => {
                expect(component.language.value).toBe(component.steps[1].language);
                expect(component.setNotes).toBeCalledWith(undefined);
                expect(component.currentStep).toBe(component.steps[1]);
                done();
            });
        });

        it('should not open discard modal on LanguageChange if form is invalid', (done) => {
            component.form.markAsDirty();
            component.saveDisabled = false;
            component.form = {
                ...component.form, ...{
                    dirty: true,
                    invalid: true,
                    status: 'INVALID',
                    get: jest.fn().mockReturnValue({}),
                    setValue: jest.fn()
                }
            };
            const event = { key: 0, value: 'German' };

            component.steps = [{
                id: 1,
                selected: true,
                language: { key: 0, value: 'German' },
                notes: 'ABC'
            }, {
                id: 2,
                selected: true,
                language: { key: 1, value: 'French' },
                notes: 'XYZ'
            }];
            component.onLanguageChange(event);
            expect(notificationService.openDiscardModal).not.toHaveBeenCalled();

            notificationRef.content.cancelled$.subscribe(() => {
                expect(component.language).not.toBe(null);
                done();
            });
        });

        it('should reset current step if form not dirty on LanguageChange', () => {
            component.form.markAsPristine();
            component.saveDisabled = false;
            jest.spyOn(component, 'setNotes');
            component.onLanguageChange('');
            expect(component.saveDisabled).toBeTruthy();
            expect(component.setNotes).toBeCalledWith(null);
        });
    });
});