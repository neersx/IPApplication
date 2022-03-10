import { ChangeDetectorRefMock, HttpClientMock } from 'mocks';
import { StateServiceMock } from 'mocks/state-service.mock';
import { PriorArtComponent } from './priorart.component';

describe('PriorArtComponent', () => {
    let component: PriorArtComponent;
    let stateService: StateServiceMock;
    let httpClientSpy;
    const cdRef = new ChangeDetectorRefMock();

    beforeEach(() => {
        httpClientSpy = new HttpClientMock();
        stateService = new StateServiceMock();
        stateService = new StateServiceMock();
        stateService.go = jest.fn();
        stateService.params = { caseKey: -999, sourceId: -111 };
        component = new PriorArtComponent(cdRef as any, stateService as any);
        component.stateParams = { caseKey: -999, sourceId: -111 };
        component.priorArtData = {
            caseIrn: '1234',
            caseKey: -999,
            sourceDocumentData: {
                sourceType: { name: 'aaa' },
                searchDescription: 'zzz'
            }
        };
    });

    it('should create the component', (() => {
        expect(component).toBeTruthy();
    }));

    it('should initialise the context and call the api', (() => {
        component.ngOnInit();
        expect(component.sourceId).toBe(-111);
        expect(component.caseKey).toBe(-999);
    }));

    it('should set the source name init', (() => {
        component.priorArtData.sourceDocumentData.isSourceDocument = true;
        component.priorArtData.sourceDocumentData.isIpDocument = false;
        component.ngOnInit();
        expect(component.caseName).toBe(component.priorArtData.caseIrn);
        expect(component.sourceDocumentData).toBe(component.priorArtData.sourceDocumentData);
        expect(component.isLoaded).toBeTruthy();
        expect(component.sourceName).toBe('aaa - zzz');
    }));

    describe('close', () => {
        it('should change states when close button is pressed', (() => {
            component.close();
            expect(stateService.go).toHaveBeenCalledWith('referenceManagement', { caseKey: -999, goToStep: 2, priorartId: -111 });
        }));
    });
});