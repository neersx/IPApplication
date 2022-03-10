import { ChangeDetectorRefMock, ElementRefMock, Renderer2Mock } from 'mocks';
import { KotModel } from './keep-on-top-notes-models';
import { KeepOnTopNotesComponent } from './keep-on-top-notes.component';

describe('HelpComponent', () => {
    let component: KeepOnTopNotesComponent;
    let renderer2Mock: any;
    let elementRef: ElementRefMock;

    beforeEach((() => {
        renderer2Mock = new Renderer2Mock();
        elementRef = new ElementRefMock();

        component = new KeepOnTopNotesComponent(new ChangeDetectorRefMock() as any, elementRef, renderer2Mock);
    }));

    it('should component initialize', () => {
        expect(component).toBeTruthy();
    });

    it('should check hasNotes', () => {
        component.notes = [
            { note: '123' },
            { note: 'xyz' }
        ];
        const notes = component.hasNotes();
        expect(notes).toBeTruthy();
    });

    it('should check TrackBy', () => {
        const index = 1;
        const notes = component.trackByFn(index, null);
        expect(notes).toEqual(1);
    });

    it('should check clickKotNote', () => {
        const kot: KotModel = {
            note: 'abc',
            expanded: true
        };
        component.clickKotNote(kot);
        expect(kot.expanded).toBeFalsy();
    });

    it('should set the itemsPerSlide & indicators from Notes when notes are less than 3', () => {
        component.notes = [
            { note: '123' },
            { note: 'xyz' }
        ];
        component.ngOnInit();
        expect(component.showIndicators).toBeFalsy();
        expect(component.itemsPerSlide).toEqual(2);
    });

    it('should set the itemsPerSlide & indicators to 3 when notes are more than 3', () => {
        component.notes = [
            { note: '123' },
            { note: 'xyz' },
            { note: 'abc' },
            { note: '456' }
        ];
        component.ngOnInit();
        expect(component.showIndicators).toBeTruthy();
        expect(component.itemsPerSlide).toEqual(3);
    });

});