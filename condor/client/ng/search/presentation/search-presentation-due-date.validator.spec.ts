import { async } from '@angular/core/testing';
import * as _ from 'underscore';
import { DueDateColumnsValidator } from './search-presentation-due-date.validator';
import { PresentationColumnView } from './search-presentation.model';

describe('CaseSearchComponent', () => {
    let service: DueDateColumnsValidator;
    const selectedColumns: Array<PresentationColumnView> = [
        { id: '9_C', parentId: null, columnKey: null, columnDescription: 'Column9', groupKey: 23, groupDescription: 'Group 23', displayName: 'Column9', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
        { id: '10_C', parentId: null, columnKey: 2, columnDescription: 'Column 10', groupKey: -44, groupDescription: null, displayName: 'Column10', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
        { id: '11_C', parentId: null, columnKey: 3, columnDescription: 'Column 5', groupKey: -45, groupDescription: null, displayName: 'Column5', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false },
        { id: '-13_G', parentId: null, columnKey: 0, columnDescription: null, groupKey: -13, groupDescription: null, displayName: 'Column8', isGroup: false, sortDirection: '', groupBySortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false, isGroupBySortOrderDisabled: false }
    ];

    beforeEach(() => {
        service = new DueDateColumnsValidator();
    });

    it('should create the component', async(() => {
        expect(service).toBeTruthy();
    }));

    it('should create the component', async(() => {
        const result = service.validate(false, selectedColumns);
        expect(result.hasAllDateColumn).toBe(false);
        expect(result.hasDueDateColumn).toBe(true);
    }));

});
