import { async } from '@angular/core/testing';
import { CaseSearchServiceMock, CaseTopicsDataService, KeyBoardShortCutService, NotificationServiceMock, SearchPresentationServiceMock, StateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable } from 'rxjs';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { DueDateColumnsValidator } from 'search/presentation/search-presentation-due-date.validator';
import { CaseSearchComponent } from './case-search.component';
import { CaseSearchViewData } from './case-search.data';

describe('CaseSearchComponent', () => {
    let c: CaseSearchComponent;
    let stepsService = { steps: null };
    const stateMock = new StateServiceMock();
    const keyBoardShortMock = new KeyBoardShortCutService();
    const caseSearchServiceMock = new CaseSearchServiceMock();
    const modalService = new ModalServiceMock();
    const dueDateColumnValidator = new DueDateColumnsValidator();
    const savedSearchService = {};
    const notificationServiceMock = new NotificationServiceMock();
    const searchPresentationService = new SearchPresentationServiceMock();
    let dueDateFilterServiceMock;
    beforeEach(() => {
        dueDateFilterServiceMock = {
            prepareFilter: jest.fn()
        };
        c = new CaseSearchComponent(stateMock as any,
            StepsPersistanceSeviceMock as any,
            CaseTopicsDataService as any,
            keyBoardShortMock as any,
            caseSearchServiceMock as any,
            modalService as any,
            searchPresentationService as any,
            dueDateColumnValidator, savedSearchService as any, notificationServiceMock as any,
            dueDateFilterServiceMock);
        c.viewData = new CaseSearchViewData();
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));
    it('should set persistance service steps null for new search', () => {
        expect(stepsService.steps).toBe(null);
    });
    it('should set persistance service steps data for saved search', () => {
        c.savedSearchData = {
            queryKey: 36,
            queryName: 'Test',
            dueDateFormData: {},
            isPublic: false,
            queryContext: 2,
            steps: [
                {
                    id: 1,
                    operator: 'OR',
                    topicsData: CaseTopicsDataService
                }]
        };
        stepsService = {
            steps: [
                {
                    id: 1,
                    operator: 'OR',
                    topicsData: CaseTopicsDataService
                }]
        };
        expect(stepsService.steps).toEqual(c.savedSearchData.steps);
    });
    it('should call discard of all topics', () => {
        const ref = {
            key: 'dataManagement',
            title: 'caseSearch.topics.dataManagement.title',
            discard: jest.fn()
        };
        const details = {
            key: 'dataManagement',
            title: 'caseSearch.topics.dataManagement.title',
            discard: jest.fn()
        };
        c.topics = { ref, details };
        c.reset();
        expect(ref.discard).toHaveBeenCalled();
        expect(details.discard).toHaveBeenCalled();
    });
    it('should return false if steps are more than 1', () => {
        c.isMultiStepMode = true;
        c.multiStepRef = {};
        c.multiStepRef.steps = ['step1', 'step2'];
        let val = c.isToggleDisabled();
        expect(val).toBe(true);

        c.isMultiStepMode = false;
        c.multiStepRef.steps = ['step1', 'step2'];
        val = c.isToggleDisabled();
        expect(val).toBe(false);
    });
    it('collects data from topics and passes filter to search results page', () => {
        const filterParams = [{ abc: '123', def: '456' }];
        c.multiStepRef = {};
        c.multiStepRef.getFilterCriteriaForSearch = jest.fn().mockReturnValue(filterParams);
        c.search(false);
        expect(c.multiStepRef.getFilterCriteriaForSearch).toHaveBeenCalled();
        expect(stateMock.go).toHaveBeenCalled();
    });

    it('check if due date modal opens on search', () => {
        c.savedSearchData = {
            queryKey: 36, queryName: 'Test', dueDateFormData: {}, steps: [{ id: 1, operator: 'OR', topicsData: CaseTopicsDataService, queryContext: 2, isPublic: false }]
        };
        c.viewData.hasDueDatePresentationColumn = true;
        c.multiStepRef = { getFilterCriteriaForSearch: jest.fn(), steps: [{ id: 1, operator: 'OR', topicsData: CaseTopicsDataService }] };
        c.openDueDate = jest.fn().mockReturnValue(new Observable());
        c.search(false);
        expect(stateMock.go).toBeCalled();
    });
});
