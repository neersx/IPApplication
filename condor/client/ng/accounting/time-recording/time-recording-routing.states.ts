import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { TimeRecordingQueryComponent } from './query/time-recording-query.component';
import { TimeRecordingComponent } from './time-recording.component';

// tslint:disable-next-line: variable-name
export const TimeRecordingState: Ng2StateDeclaration = {
    name: 'timeRecording',
    url: '/accounting/time/:caseId',
    component: TimeRecordingComponent,
    data: {
        pageTitle: 'accounting.time.recording.pageTitle'
    },
    params: {
        entryDate: null,
        staff: null,
        entryNo: null,
        caseId: {
            squash: true,
            type: 'int',
            value: null
        },
        copyFromEntry: null
    },
    resolve:
        [
            {
                token: 'stateParams',
                deps: [Transition],
                resolveFn: getStateParameters
            }
        ]
};
// tslint:disable-next-line: variable-name
export const TimeRecordingForCaseState: Ng2StateDeclaration = {
    name: 'timeRecordingForCase',
    url: '/accounting/time/case',
    component: TimeRecordingComponent,
    data: {
        pageTitle: 'accounting.time.recording.pageTitle'
    },
    params: {
        entryDate: null,
        staff: null,
        entryNo: null,
        caseKey: {
            squash: true,
            type: 'int',
            value: null
        },
        copyFromEntry: null
    },
    resolve:
        [
            {
                token: 'stateParams',
                deps: [Transition],
                resolveFn: getStateParameters
            }
        ]
};

// tslint:disable-next-line: variable-name
export const TimeRecordingQueryState: Ng2StateDeclaration = {
    name: 'timeRecordingQuery',
    url: '/accounting/time/query',
    component: TimeRecordingQueryComponent,
    data: {
        pageTitle: 'accounting.time.query.pageTitle'
    },
    params: {
        entryDate: null,
        staff: null,
        entryNo: null,
        caseId: null,
        caseRef: null
    },
    resolve:
    [
        {
            token: 'stateParams',
            deps: [Transition],
            resolveFn: getStateParameters
        }
    ]
};

// tslint:disable-next-line: only-arrow-functions
export function getStateParameters($transition: Transition): any {
    return {
        entryDate: $transition.params().entryDate,
        staff: $transition.params().staff,
        entryNo: $transition.params().entryNo,
        caseId: $transition.params().caseId,
        caseKey: $transition.params().caseKey,
        caseRef: $transition.params().caseRef,
        copyFromEntry: $transition.params().copyFromEntry
    };
}
