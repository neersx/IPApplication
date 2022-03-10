import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { TaskPlannerTabConfigItem } from './task-planner-configuration.model';
import { TaskPlannerConfigurationService } from './task-planner-configuration.service';

describe('TaskPlannerConfigurationService', () => {

    let service: TaskPlannerConfigurationService;
    let httpMock: HttpClientMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        httpMock.get.mockReturnValue(of({}));
        httpMock.put.mockReturnValue(of({}));
        service = new TaskPlannerConfigurationService(httpMock as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });

    it('validate getProfileTabData', () => {
        service.getProfileTabData();
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/taskPlannerConfiguration');
    });

    it('validate save', () => {
        const tabsData: Array<TaskPlannerTabConfigItem> = [
            {
                id: 123,
                isDeleted: false,
                profile: { key: 1, code: 1, name: 'test 1' },
                tab1: { key: 11, searchName: 'saved search 1' },
                tab2: { key: 22, searchName: 'saved search 22' },
                tab3: { key: 33, searchName: 'saved search 3' }
            }
        ];
        service.save(tabsData);
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/taskPlannerConfiguration/save', tabsData);
    });
});