import { PriorArtServiceMock } from 'cases/prior-art/priorart.service.mock';
import { FamilyNameCaseDetailsComponent } from './family-name-case-details.component';

describe('FamilyNameCaseDetailsComponent', () => {

    const service = new PriorArtServiceMock();
    let component: FamilyNameCaseDetailsComponent;

    beforeEach(() => {
        component = new FamilyNameCaseDetailsComponent(service as any, { keys: { priorart: { linkedFamilyCaseDetailsGrid: jest.fn() } } } as any);
    });

    it('should create the component', (() => {
        expect(component).toBeTruthy();
    }));
    it('should initialise the grid', () => {
        component.ngOnInit();
        expect(component.caseDetailsGridOptions).toBeDefined();
        expect(component.caseDetailsGridOptions.columns[0]).toEqual(expect.objectContaining({field: 'irn'}));
        expect(component.caseDetailsGridOptions.columns[1]).toEqual(expect.objectContaining({ field: 'officialNumber' }));
        expect(component.caseDetailsGridOptions.columns[2]).toEqual(expect.objectContaining({ field: 'jurisdiction' }));
    });
    it('should call the service to populate the grid', () => {
        component.ngOnInit();
        component.caseDetailsGridOptions.read$({
            skip: 0,
            take: 10,
            sortBy: 'id',
            sortDir: 'desc',
            filters: [],
            filterEmpty: true
        });
        expect(service.getFamilyCaseListDetails$).toHaveBeenCalledTimes(1);
    });
});