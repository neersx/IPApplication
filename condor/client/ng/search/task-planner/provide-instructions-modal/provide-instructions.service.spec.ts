import { HttpClientMock } from 'mocks';
import { ProvideInstructionsService } from './provide-instructions.service';

describe('ProvideInstructionsService', () => {

    let service: ProvideInstructionsService;
    let httpMock: HttpClientMock;

    beforeEach(() => {
        httpMock = new HttpClientMock();
        service = new ProvideInstructionsService(httpMock as any);
    });

    it('should create the service', () => {
        expect(service).toBeTruthy();
    });

    it('verify getProvideInstructions', () => {
        const rowKey = 'C^12^234';
        service.getProvideInstructions(rowKey);
        expect(httpMock.get).toHaveBeenCalledWith('api/provideInstructions/get/' + rowKey);
    });

    it('verify getProvideInstructions', () => {
        const request = { taskPlannerRowKey: 'C^12^3434', provideInstruction: { instructionDate: new Date(), instructions: [] } };
        service.save(request);
        expect(httpMock.post).toHaveBeenCalledWith('api/provideInstructions/instruct/', request);
    });

});
