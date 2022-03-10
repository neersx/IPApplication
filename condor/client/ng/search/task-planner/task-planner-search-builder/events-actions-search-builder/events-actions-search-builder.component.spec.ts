import { FormControl, NgForm } from '@angular/forms';
import { ChangeDetectorRefMock } from 'mocks';
import { SearchOperator } from 'search/common/search-operators';
import { EventsActionsSearchBuilderComponent } from './events-actions-search-builder.component';

describe('EventsActionsSearchBuilderComponent', () => {
    let component: EventsActionsSearchBuilderComponent;
    let changeDetectorRef: ChangeDetectorRefMock;
    let formData: any;
    beforeEach(() => {
        changeDetectorRef = new ChangeDetectorRefMock();
        component = new EventsActionsSearchBuilderComponent(changeDetectorRef as any);
        formData = {
            eventsAndActions: {
                event: { operator: '0', value: [{ key: 12, value: 'Test event' }] },
                eventCategory: { operator: '0', value: { key: 45, value: 'Test event category' } },
                eventNoteType: { operator: '0', value: { key: 667, code: 'event type' } },
                eventNotes: { operator: '2', value: 'test note 1' },
                action: { operator: '0', value: { key: 981, code: 'action 1' } }
            }
        };
        component.topic = {
            params: {
                viewData: {
                    showEventNoteType: true,
                    formData
                }
            }
        } as any;

        component.eventsActionsForm = new NgForm(null, null);
        component.eventsActionsForm.form.addControl('event', new FormControl(null, null));
        component.eventsActionsForm.form.addControl('eventCategory', new FormControl(null, null));
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.ngOnInit();
        expect(component.viewData).toBeDefined();
        expect(component.formData).toBe(formData.eventsAndActions);
    });

    it('validate initFormData', () => {
        component.initFormData();
        expect(component.formData).toBeDefined();
        expect(component.formData.event.operator).toEqual(SearchOperator.equalTo);
        expect(component.formData.eventCategory.operator).toEqual(SearchOperator.equalTo);
        expect(component.formData.eventNotes.operator).toEqual(SearchOperator.startsWith);
    });

    it('validate clear', () => {
        component.formData.event = { value: [{ key: '-487', value: 'test 1' }], operator: SearchOperator.exists };
        component.formData.eventCategory = { value: { key: '3', code: 'A' }, operator: SearchOperator.exists };
        component.formData.eventNotes = { value: 'Test note 2', operator: SearchOperator.notExists };
        component.clear();
        expect(component.formData.event.operator).toEqual(SearchOperator.equalTo);
        expect(component.formData.event.value).toBeUndefined();
        expect(component.formData.eventCategory.operator).toEqual(SearchOperator.equalTo);
        expect(component.formData.eventCategory.value).toBeUndefined();
        expect(component.formData.eventNotes.operator).toEqual(SearchOperator.startsWith);
        expect(component.formData.eventNotes.value).toBeUndefined();
        expect(changeDetectorRef.markForCheck).toHaveBeenCalled();
    });

    it('validate isValid', () => {
        const result = component.isValid();
        expect(result).toBeTruthy();
    });

    it('validate getFormData', () => {
        const events = [{ key: 11, value: 'Event 1' }, { key: 12, value: 'Event 2' }];
        const eventCategory = [{ key: 21, value: 'cate 1' }];
        const actions = [{ key: 31, code: 'AB', value: 'action 1' }, { key: 32, code: 'XY', value: 'action 2' }];
        component.formData.event = { operator: SearchOperator.notEqualTo, value: events };
        component.formData.eventCategory = { operator: SearchOperator.equalTo, value: eventCategory };
        component.formData.action = { operator: SearchOperator.equalTo, value: actions };
        component.formData.eventNotes = { operator: SearchOperator.startsWith, value: 'note1' };
        const result = component.getFormData();
        expect(result.searchRequest.eventKeys).toEqual({ operator: SearchOperator.notEqualTo, value: '11,12' });
        expect(result.searchRequest.eventCategoryKeys).toEqual({ operator: SearchOperator.equalTo, value: '21' });
        expect(result.searchRequest.actions.actionKeys).toEqual({ operator: SearchOperator.equalTo, value: 'AB,XY' });
        expect(result.searchRequest.eventNoteText).toEqual({ operator: SearchOperator.startsWith, value: 'note1' });
        expect(result.formData.eventsAndActions).toBe(component.formData);
    });

    it('validate changeOperator with equalTo', () => {
        const events = [{ key: 11, value: 'Event 1' }, { key: 12, value: 'Event 2' }];
        component.formData.event = { operator: SearchOperator.equalTo, value: events };
        component.changeOperator('event');
        expect(component.formData.event.value).toBe(events);
    });

    it('validate changeOperator exists', () => {
        const events = [{ key: 11, value: 'Event 1' }, { key: 12, value: 'Event 2' }];
        component.formData.event = { operator: SearchOperator.exists, value: events };
        component.changeOperator('event');
        expect(component.formData.event.value).toBeNull();
    });
    it('validate isDirty when form is dirty', () => {
        component.eventsActionsForm.form.addControl('displayName', new FormControl(null));
        component.eventsActionsForm.controls.displayName.setValue('data');
        component.eventsActionsForm.controls.displayName.markAsDirty();
        expect(component.isDirty()).toEqual(true);
    });
    it('validate isDirty when form is not dirty', () => {
        component.eventsActionsForm.form.addControl('displayName', new FormControl(null));
        expect(component.isDirty()).toEqual(false);
    });
    it('validate setPristine', () => {
        component.eventsActionsForm.form.addControl('displayName', new FormControl(null));
        component.eventsActionsForm.controls.displayName.setValue('data');
        component.eventsActionsForm.controls.displayName.markAsDirty();
        component.setPristine();
        expect(component.isDirty()).toEqual(false);
    });
});
