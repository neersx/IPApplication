import { Injectable } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import * as _ from 'underscore';
import { TimeEntryEx } from '../time-recording-model';

@Injectable()
export class TimeGridHelper {
    selectedItem: any;

    constructor(readonly localSettings: LocalSettings) { }

    kendoAddOnSave(gridOptions: any): void {
        setTimeout(() => {
            gridOptions.enableGridAdd = true;
            gridOptions.addOnSave();
        }, 100);
    }

    static canNotPost(dataItem: any): boolean {
        return dataItem.isPosted || dataItem.isIncomplete || dataItem.isContinuedParent || !TimeGridHelper.isSavedEntry(dataItem.entryNo) || dataItem.isTimer;
    }

    static canNotContinue(dataItem: any): boolean {
        return dataItem.isPosted || dataItem.isContinuedParent || !TimeGridHelper.isSavedEntry(dataItem.entryNo) || dataItem.isTimer;
    }

    static canNotEdit(dataItem: any): boolean {
        return dataItem.isContinuedParent || TimeGridHelper.canNotDelete(dataItem);
    }

    static canNotEditPosted(dataItem: any): boolean {
        return dataItem.isContinuedParent || dataItem.isLastChild || _.isNumber(dataItem.parentEntryNo);
    }

    static canNotDelete(dataItem: any): boolean {
        return !TimeGridHelper.isSavedEntry(dataItem.entryNo);
    }

    static canNotDuplicate(dataItem: any): boolean {
        return dataItem.isLastChild || TimeGridHelper.canNotEdit(dataItem);
    }

    static canNotMaintainCaseNarrative(dataItem): boolean {
        return dataItem.caseKey === null || dataItem.caseKey === undefined;
    }

    static canNotOpenWebLinks(dataItem): boolean {
        return dataItem.caseKey === null || dataItem.caseKey === undefined;
    }

    static isSavedEntry = (entryNo: any): boolean => {
        return entryNo === 0 || !!entryNo;
    };

    initializeTaskItems = (associatedActions: any, allowedActions: Array<string>): Array<any> => {
        const kendoTasks = {
            CONTINUE_TIMER: {
                id: 'continueTimer',
                text: 'accounting.time.recording.continueTimer',
                icon: 'cpa-icon cpa-icon-clock-timer',
                actionName: 'CONTINUE_TIMER',
                action: associatedActions.CONTINUE_TIMER,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || dataItem.durationOnly || TimeGridHelper.canNotContinue(dataItem);
                }
            },
            CONTINUE_TIME: {
                id: 'continue',
                text: 'Continue',
                icon: 'cpa-icon cpa-icon-clock-o',
                actionName: 'CONTINUE_TIME',
                action: associatedActions.CONTINUE_TIME,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || dataItem.durationOnly || TimeGridHelper.canNotContinue(dataItem);
                }
            },
            EDIT_TIME: {
                id: 'edit',
                text: 'Edit',
                icon: 'cpa-icon cpa-icon-pencil-square-o',
                action: associatedActions.EDIT_TIME,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || TimeGridHelper.canNotEdit(dataItem);
                },
                evalText(dataItem): string {
                    if (dataItem.isPosted) {
                        return 'accounting.time.editPostedTime.button';
                    }

                    return _.isNumber(dataItem.parentEntryNo) ? 'accounting.time.recording.editContinued' : 'Edit';
                }
            },
            CHANGE_ENTRY_DATE: {
                id: 'changeEntryDate',
                text: 'accounting.time.recording.changeEntryDate',
                icon: 'cpa-icon cpa-icon-calendar',
                action: associatedActions.CHANGE_ENTRY_DATE,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || dataItem.isTimer || (dataItem.isPosted ? TimeGridHelper.canNotEditPosted(dataItem) : TimeGridHelper.canNotEdit(dataItem));
                }
            },
            POST_TIME: {
                id: 'post',
                text: 'accounting.time.postTime.button',
                icon: 'cpa-icon cpa-icon-clock-o',
                action: associatedActions.POST_TIME,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || TimeGridHelper.canNotPost(dataItem);
                }
            },
            DELETE_TIME: {
                id: 'delete',
                text: 'accounting.time.recording.delete',
                icon: 'cpa-icon cpa-icon-trash',
                action: associatedActions.DELETE_TIME,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return TimeGridHelper.canNotDelete(dataItem);
                }
            },
            ADJUST_VALUES: {
                id: 'adjust',
                text: 'accounting.time.recording.adjustValues',
                icon: 'cpa-icon cpa-icon-pencil-square-o',
                action: associatedActions.ADJUST_VALUES,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || TimeGridHelper.canNotPost(dataItem);
                }
            },
            DUPLICATE_ENTRY: {
                id: 'duplicate',
                text: 'accounting.time.recording.duplicateEntry',
                icon: 'cpa-icon cpa-icon-plus-stack-square-o',
                action: associatedActions.DUPLICATE_ENTRY,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || TimeGridHelper.canNotDuplicate(dataItem);
                }
            },
            SEPARATOR: {
                id: 'Separator1',
                isSeparator: true
            },
            CASE_NARRATIVE: {
                id: 'caseNarrative',
                text: 'accounting.time.recording.caseNarrative',
                icon: 'cpa-icon cpa-icon-items-o',
                action: associatedActions.CASE_NARRATIVE,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || TimeGridHelper.canNotMaintainCaseNarrative(dataItem);
                }
            },
            CASE_WEBLINKS: {
                id: 'caseWebLinks',
                text: 'caseTaskMenu.openCaseWebLinks',
                icon: 'cpa-icon cpa-icon-bookmark',
                action: associatedActions.CASE_WEBLINKS,
                items: [],
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || TimeGridHelper.canNotOpenWebLinks(dataItem);
                }
            },
            CASE_DOCUMENTS: {
                id: 'caseDocuments',
                text: 'accounting.time.recording.caseDocuments',
                icon: 'cpa-icon cpa-icon-paperclip',
                action: associatedActions.CASE_DOCUMENTS,
                evalDisabled(dataItem: TimeEntryEx, entryInEdit: boolean): boolean {
                    return entryInEdit || !_.isNumber(dataItem.caseKey);
                }
            }
        };

        return _.chain(kendoTasks as any)
            .pick(allowedActions)
            .values()
            .value() as Array<any>;
    };

    reevaluateWhileDisplaying = (taskMenuItems: Array<any>, dataItem: TimeEntryEx, entryIsInEdit: boolean): Array<any> => {
        _.each(taskMenuItems, (i) => {
            if (i.evalDisabled) {
                i.disabled = i.evalDisabled(dataItem, entryIsInEdit);
            }
            if (i.evalText) {
                i.text = i.evalText(dataItem);
            }
        });

        return taskMenuItems;
    };

    getColumnSelectionLocalSetting = () => {
        return this.localSettings.keys.accounting.timesheet.columnsSelection;
    };

    getColumns = (): Array<GridColumnDefinition> => [
        {
            title: '',
            field: 'isLastChildOrIncomplete',
            template: true,
            width: 20,
            sortable: false,
            includeInChooser: false,
            fixed: true
        },
        {
            title: '',
            field: 'isPosted',
            template: true,
            width: 32,
            sortable: {
                allowUnsort: true
            },
            includeInChooser: false,
            fixed: true
        },
        {
            title: 'accounting.time.fields.start',
            field: 'start',
            template: true,
            width: 60
        },
        {
            title: 'accounting.time.fields.finish',
            field: 'finish',
            template: true,
            includeInChooser: true,
            width: 60
        },
        {
            title: 'accounting.time.fields.time',
            field: 'elapsedTimeInSeconds',
            template: true,
            includeInChooser: false,
            width: 60
        },
        {
            title: 'accounting.time.fields.units',
            field: 'totalUnits',
            template: true,
            headerClass: 'right-aligned',
            hidden: true,
            width: 40
        },
        {
            title: 'accounting.time.fields.case',
            field: 'caseReference',
            template: true,
            includeInChooser: false
        },
        {
            title: 'accounting.time.fields.name',
            field: 'name',
            template: true,
            includeInChooser: true
        },
        {
            title: 'accounting.time.fields.activity',
            field: 'activity',
            template: true,
            includeInChooser: false
        },
        {
            title: 'accounting.time.fields.chargeOutRate',
            field: 'chargeOutRate',
            template: true,
            headerClass: 'right-aligned',
            hidden: true,
            width: 60
        },
        {
            title: 'accounting.time.fields.localValue',
            field: 'localValue',
            template: true,
            headerClass: 'right-aligned',
            width: 55
        },
        {
            title: 'accounting.time.fields.foreignValue',
            field: 'foreignValue',
            template: true,
            headerClass: 'right-aligned',
            width: 55
        },
        {
            title: 'accounting.time.fields.localDiscount',
            field: 'localDiscount',
            template: true,
            headerClass: 'right-aligned',
            hidden: true,
            width: 60
        },
        {
            title: 'accounting.time.fields.foreignDiscount',
            field: 'foreignDiscount',
            template: true,
            headerClass: 'right-aligned',
            hidden: true,
            width: 60
        }
    ];
}