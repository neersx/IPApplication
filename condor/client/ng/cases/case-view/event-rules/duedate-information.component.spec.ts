
import { DueDateCalculationInformationComponent } from './duedate-information.component';

describe('DueDateCalculationInformationComponent', () => {

    let component: DueDateCalculationInformationComponent;

    beforeEach(() => {
        component = new DueDateCalculationInformationComponent();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('should initialise the grid', () => {
        component.ngOnInit();
        expect(component.satisfyingEventGridOptions).toBeDefined();
        expect(component.satisfyingEventGridOptions.columns.length).toBe(2);
        expect(component.satisfyingEventGridOptions.columns[0].field).toBe('eventKey');
        expect(component.satisfyingEventGridOptions.columns[1].field).toBe('formattedDescription');
        expect(component.satisfyingEventGridOptions.navigable).toBeFalsy();
        expect(component.dateComparisonGridOptions).toBeDefined();
        expect(component.dateComparisonGridOptions.columns.length).toBe(3);
        expect(component.dateComparisonGridOptions.columns[0].field).toBe('leftHandSide');
        expect(component.dateComparisonGridOptions.columns[1].field).toBe('comparison');
        expect(component.dateComparisonGridOptions.columns[2].field).toBe('rightHandSide');
        expect(component.dateComparisonGridOptions.navigable).toBeFalsy();
    });
});