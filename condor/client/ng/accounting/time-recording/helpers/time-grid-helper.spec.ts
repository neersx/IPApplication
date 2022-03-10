import { fakeAsync, tick } from '@angular/core/testing';
import { LocalSettings } from 'core/local-settings';
import * as _ from 'underscore';
import { TimeGridHelper } from './time-grid-helper';

describe('Service: TimeGridHelperService', () => {

    let localSettings: LocalSettings;
    let service: TimeGridHelper;

    beforeEach(() => {
        localSettings = new LocalSettings({} as any);
    });

    it('should create an instance', () => {
        service = new TimeGridHelper(localSettings);
        expect(service).toBeTruthy();
    });

    it('should return columns definitions', () => {
        service = new TimeGridHelper(localSettings);
        const result = service.getColumns();

        expect(result.length).toBe(14);
        expect(_.where(result, { hidden: true }).length).toBe(4);
        expect(_.where(result, { includeInChooser: false }).length).toBe(5);
        expect(_.where(result, { sortable: false }).length).toBe(1);
    });

    it('isSavedEntry returns appropriate result, if saved entry', () => {
        let isSaved = TimeGridHelper.isSavedEntry(10);
        expect(isSaved).toBeTruthy();

        isSaved = TimeGridHelper.isSavedEntry(0);
        expect(isSaved).toBeTruthy();

        isSaved = TimeGridHelper.isSavedEntry(null);
        expect(isSaved).toBeFalsy();

        isSaved = TimeGridHelper.isSavedEntry(undefined);
        expect(isSaved).toBeFalsy();
    });

    describe('initializeTaskItems', () => {
        const associatedActions = {
            EDIT_TIME: jest.fn().mockName('editFn'),
            DELETE_TIME: jest.fn().mockName('deleteFn'),
            CHANGE_ENTRY_DATE: jest.fn().mockName('changeEntryDateFn'),
            CONTINUE_TIME: jest.fn().mockName('continueFn'),
            ADJUST_VALUES: jest.fn().mockName('adjustFn'),
            POST_TIME: jest.fn().mockName('postFn'),
            CONTINUE_TIMER: jest.fn().mockName('continueTimerFn'),
            CASE_WEBLINKS: jest.fn().mockName('caseWebLinksFn')
        };

        beforeEach(() => {
            service = new TimeGridHelper(localSettings);
        });

        it('uses associatedActions to set actions of task items', () => {
            const allActions = ['EDIT_TIME', 'DELETE_TIME', 'CHANGE_ENTRY_DATE', 'CONTINUE_TIME', 'ADJUST_VALUES', 'POST_TIME', 'CONTINUE_TIMER', 'CASE_WEBLINKS'];

            const result = service.initializeTaskItems(associatedActions, allActions);
            const keys = _.pluck(result, 'id');

            expect(_.contains(keys, 'continue')).toBeTruthy();
            expect(_.findWhere(result, { id: 'continue' }).action.getMockName()).toBe('continueFn');

            expect(_.contains(keys, 'edit')).toBeTruthy();
            expect(_.findWhere(result, { id: 'edit' }).action.getMockName()).toBe('editFn');

            expect(_.contains(keys, 'changeEntryDate')).toBeTruthy();
            expect(_.findWhere(result, { id: 'changeEntryDate' }).action.getMockName()).toBe('changeEntryDateFn');

            expect(_.contains(keys, 'post')).toBeTruthy();
            expect(_.findWhere(result, { id: 'post' }).action.getMockName()).toBe('postFn');

            expect(_.contains(keys, 'delete')).toBeTruthy();
            expect(_.findWhere(result, { id: 'delete' }).action.getMockName()).toBe('deleteFn');

            expect(_.contains(keys, 'adjust')).toBeTruthy();
            expect(_.findWhere(result, { id: 'adjust' }).action.getMockName()).toBe('adjustFn');

            expect(_.contains(keys, 'continueTimer')).toBeTruthy();
            expect(_.findWhere(result, { id: 'continueTimer' }).action.getMockName()).toBe('continueTimerFn');

            expect(_.contains(keys, 'caseWebLinks')).toBeTruthy();
            expect(_.findWhere(result, { id: 'caseWebLinks' }).action.getMockName()).toBe('caseWebLinksFn');
        });

        it('uses passed allowed actions, while determining task items list', () => {
            const allowedActions = ['EDIT_TIME'];

            const result = service.initializeTaskItems(associatedActions, allowedActions);
            const keys = _.pluck(result, 'id');

            expect(result.length).toBe(1);
            expect(_.contains(keys, 'edit'));
        });

        it('if passed allowed actions is empty, empty task items list is returned', () => {
            const allowedActions = [];

            const result = service.initializeTaskItems(associatedActions, allowedActions);
            const keys = _.pluck(result, 'id');

            expect(result.length).toBe(0);
        });

        it('continue time - evalDisabled, considers all required conditions', () => {
            const allowedActions = ['CONTINUE_TIME'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            expect(result.length).toBe(1);
            const continueTime = result[0];

            expect(continueTime.evalDisabled({})).toBeTruthy();
            expect(continueTime.evalDisabled({ entryNo: 10, isPosted: true })).toBeTruthy();
            expect(continueTime.evalDisabled({ entryNo: 10, isPosted: false, isTimer: true })).toBeTruthy();
            expect(continueTime.evalDisabled({ entryNo: 10, isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: true })).toBeTruthy();
            expect(continueTime.evalDisabled({ entryNo: null, isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false })).toBeTruthy();
            expect(continueTime.evalDisabled({ entryNo: 10, isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false, durationOnly: true })).toBeTruthy();
            expect(continueTime.evalDisabled({ entryNo: 10, isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false, durationOnly: false }, true)).toBeTruthy();

            expect(continueTime.evalDisabled({ entryNo: 10, isPosted: false, isTimer: false, isIncomplete: true })).toBeFalsy();
            expect(continueTime.evalDisabled({ isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false, entryNo: 10, durationOnly: false })).toBeFalsy();
        });

        it('change entry date - evalDisabled, considers all required conditions', () => {
            const allowedActions = ['CHANGE_ENTRY_DATE'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            expect(result.length).toBe(1);
            const changeEntry = result[0];

            expect(changeEntry.evalDisabled({ isPosted: false, isContinuedParent: true })).toBeTruthy();
            expect(changeEntry.evalDisabled({ isPosted: false, isContinuedParent: false, entryNo: null })).toBeTruthy();
            expect(changeEntry.evalDisabled({ isPosted: false, isContinuedParent: false, entryNo: 10, isTimer: true })).toBeTruthy();
            expect(changeEntry.evalDisabled({ isPosted: false, isContinuedParent: false, entryNo: 10 }, true)).toBeTruthy();
            expect(changeEntry.evalDisabled({ isPosted: true, isContinuedParent: true, entryNo: 10 }, true)).toBeTruthy();
            expect(changeEntry.evalDisabled({ isPosted: true, isContinuedParent: true, entryNo: 10 })).toBeTruthy();

            expect(changeEntry.evalDisabled({ isPosted: true, isContinuedParent: false, isLastChild: false, parentEntryNo: null })).toBeFalsy();
            expect(changeEntry.evalDisabled({ isPosted: false, isContinuedParent: false, entryNo: 10 })).toBeFalsy();
        });

        it('post time - evalDisabled, considers all required conditions', () => {
            const allowedActions = ['POST_TIME'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            expect(result.length).toBe(1);
            const postTime = result[0];

            expect(postTime.evalDisabled({ isPosted: true })).toBeTruthy();
            expect(postTime.evalDisabled({ isPosted: false, isTimer: true })).toBeTruthy();
            expect(postTime.evalDisabled({ isPosted: false, isTimer: false, isIncomplete: true })).toBeTruthy();
            expect(postTime.evalDisabled({ isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: true })).toBeTruthy();
            expect(postTime.evalDisabled({ isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false, entryNo: null })).toBeTruthy();
            expect(postTime.evalDisabled({ isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false, entryNo: 10, durationOnly: false }, true)).toBeTruthy();

            expect(postTime.evalDisabled({ isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false, entryNo: 10, durationOnly: false })).toBeFalsy();
        });

        it('delete time - evalDisabled, considers all required conditions', () => {
            const allowedActions = ['DELETE_TIME'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            expect(result.length).toBe(1);
            const deleteTime = result[0];

            expect(deleteTime.evalDisabled({ isPosted: false, isContinuedParent: true })).toBeTruthy();
            expect(deleteTime.evalDisabled({ isPosted: false, isContinuedParent: false, entryNo: null })).toBeTruthy();

            expect(deleteTime.evalDisabled({ isPosted: true, parentEntryNo: 100, entryNo: 10 })).toBeFalsy();
            expect(deleteTime.evalDisabled({ isPosted: true, isContinuedParent: true, entryNo: 10 }, true)).toBeFalsy();
            expect(deleteTime.evalDisabled({ isPosted: false, isContinuedParent: false, entryNo: 10 }, true)).toBeFalsy();
            expect(deleteTime.evalDisabled({ isPosted: false, isContinuedParent: false, entryNo: 10 })).toBeFalsy();
            expect(deleteTime.evalDisabled({ isPosted: true, isContinuedParent: false, isLastChild: null, entryNo: 10 })).toBeFalsy();
        });

        it('adjust time - evalDisabled, considers all required conditions', () => {
            const allowedActions = ['ADJUST_VALUES'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            expect(result.length).toBe(1);
            const adjustValues = result[0];

            expect(adjustValues.evalDisabled({ isPosted: true, entryNo: 10 })).toBeTruthy();
            expect(adjustValues.evalDisabled({ isPosted: false, isTimer: true, entryNo: 10 })).toBeTruthy();
            expect(adjustValues.evalDisabled({ isPosted: false, isTimer: false, isContinuedParent: true, entryNo: 10 })).toBeTruthy();
            expect(adjustValues.evalDisabled({ isPosted: false, isTimer: false, isContinuedParent: false, entryNo: null })).toBeTruthy();
            expect(adjustValues.evalDisabled({ isPosted: false, isTimer: false, isContinuedParent: false, entryNo: null, isIncomplete: true })).toBeTruthy();
            expect(adjustValues.evalDisabled({ isPosted: false, isTimer: false, isContinuedParent: false, entryNo: 10, isIncomplete: false }, true)).toBeTruthy();

            expect(adjustValues.evalDisabled({ isPosted: false, isTimer: false, isContinuedParent: false, entryNo: 10 })).toBeFalsy();
        });

        it('continue as timer - evalDisabled, considers all required conditions', () => {
            const allowedActions = ['CONTINUE_TIMER'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            expect(result.length).toBe(1);
            const continueTimer = result[0];

            expect(continueTimer.evalDisabled({})).toBeTruthy();
            expect(continueTimer.evalDisabled({ entryNo: 1, isPosted: true })).toBeTruthy();
            expect(continueTimer.evalDisabled({ entryNo: 1, isPosted: false, isTimer: true })).toBeTruthy();
            expect(continueTimer.evalDisabled({ entryNo: 1, isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: true })).toBeTruthy();
            expect(continueTimer.evalDisabled({ entryNo: null, isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false })).toBeTruthy();
            expect(continueTimer.evalDisabled({ entryNo: 10, isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false, durationOnly: true })).toBeTruthy();
            expect(continueTimer.evalDisabled({ entryNo: 10, isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false, durationOnly: false }, true)).toBeTruthy();

            expect(continueTimer.evalDisabled({ entryNo: 1, isPosted: false, isTimer: false, isIncomplete: true })).toBeFalsy();
            expect(continueTimer.evalDisabled({ entryNo: 1, isPosted: false, isTimer: false, isIncomplete: false, isContinuedParent: false, durationOnly: false })).toBeFalsy();
        });
        it('edit timer - evalText checks if entry is continued', () => {
            const allowedActions = ['EDIT_TIME'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            expect(result.length).toBe(1);
            const editTimeTask = result[0];

            expect(editTimeTask.evalText({ parentEntryNo: 0 })).toBe('accounting.time.recording.editContinued');
            expect(editTimeTask.evalText({ parentEntryNo: 1 })).toBe('accounting.time.recording.editContinued');
            expect(editTimeTask.evalText({ parentEntryNo: null })).toBe('Edit');
            expect(editTimeTask.evalText({ parentEntryNo: '' })).toBe('Edit');
        });

        it('edit time - evalText returns appropriate text', () => {
            const allowedActions = ['EDIT_TIME'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            const editTimeTask = result[0];
            expect(editTimeTask.evalText({ isPosted: true })).toBe('accounting.time.editPostedTime.button');
            expect(editTimeTask.evalText({ parentEntryNo: 100 })).toBe('accounting.time.recording.editContinued');
            expect(editTimeTask.evalText({})).toBe('Edit');
        });

        it('edit time - evalDisabled', () => {
            const allowedActions = ['EDIT_TIME'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            const editTimeTask = result[0];
            expect(editTimeTask.evalDisabled({}, true)).toBeTruthy();
            expect(editTimeTask.evalDisabled({ isContinuedParent: true }, false)).toBeTruthy();
            expect(editTimeTask.evalDisabled({ entryNo: undefined }, false)).toBeTruthy();
            expect(editTimeTask.evalDisabled({ entryNo: 1, parentEntryNo: 10 }, false)).toBeFalsy();
            expect(editTimeTask.evalDisabled({ entryNo: 2, isLastChild: true }, false)).toBeFalsy();
            expect(editTimeTask.evalDisabled({ entryNo: 1, isPosted: true, parentEntryNo: 10 }, false)).toBeFalsy();
            expect(editTimeTask.evalDisabled({ entryNo: 2, isPosted: true, isLastChild: true }, false)).toBeFalsy();
            expect(editTimeTask.evalDisabled({ entryNo: 100 }, false)).toBeFalsy();
        });
        it('case web links - evalDisabled', () => {
            const allowedActions = ['CASE_WEBLINKS'];
            const result = service.initializeTaskItems(associatedActions, allowedActions);

            const caseWebLinksTask = result[0];
            expect(caseWebLinksTask.evalDisabled({}, true)).toBeTruthy();
            expect(caseWebLinksTask.evalDisabled({ isContinuedParent: true }, false)).toBeTruthy();
            expect(caseWebLinksTask.evalDisabled({ entryNo: undefined, caseKey: 10 }, false)).toBeFalsy();
            expect(caseWebLinksTask.evalDisabled({ entryNo: 1, caseKey: 10 }, false)).toBeFalsy();
        });
    });

    describe('addOnSave', () => {
        it('enables Add and calls save', fakeAsync(() => {
            service = new TimeGridHelper(localSettings);
            const gridOptions = { addOnSave: jest.fn(), enableGridAdd: Boolean };
            service.kendoAddOnSave(gridOptions);
            tick(100);
            expect(gridOptions.enableGridAdd).toBeTruthy();
            expect(gridOptions.addOnSave).toHaveBeenCalled();
        }));
    });
});