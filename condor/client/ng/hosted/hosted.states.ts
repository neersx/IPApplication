// tslint:disable: only-arrow-functions
import { Ng2StateDeclaration, Transition } from '@uirouter/angular';
import { HostedComponent } from './hosted.component';

export function getStateParameters($transition: Transition): any {
    return $transition.params();
}

export const hostedCaseViewState: Ng2StateDeclaration = {
    name: 'hostedCaseView',
    url: '/hosted/CaseView/:id?:programId:section:hostId:genericKey',
    component: HostedComponent,
    params: {
        id: {
            type: 'int'
        },
        rowKey: undefined,
        section: '',
        programId: '',
        levelUpState: undefined,
        hostId: '',
        genericKey: {
            type: 'int'
        }
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            }
        ],
    data: {
        pageTitle: 'caseview.pageTitle',
        hasContextNavigation: true
    }
};

export const hostedCaseSearchResultState: Ng2StateDeclaration = {
    name: 'hostedSearchResult',
    url: '/hosted/search/searchresult?:deferLoad:hostId',
    params: {
        deferLoad: '',
        hostId: ''
    },
    component: HostedComponent,
    data: {
        pageTitle: 'caseSearchResults.pageTitle'
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            }
        ]
};

export const hostedCasePresentationState: Ng2StateDeclaration = {
    name: 'hostedSearchPresentation',
    url: '/hosted/search/presentation?:deferLoad:hostId:queryContextKey:queryKey',
    params: {
        deferLoad: '',
        hostId: '',
        queryContextKey: '',
        queryKey: '',
        selectedColumns: null
    },
    component: HostedComponent,
    data: {
        pageTitle: 'caseSearchResults.pageTitle'
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            }
        ]
};

export const hostedNameViewState: Ng2StateDeclaration = {
    name: 'hostedNameView',
    url: '/hosted/NameView/:id?:section:hostId',
    component: HostedComponent,
    params: {
        id: {
            type: 'int'
        },
        section: '',
        hostId: ''
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            }
        ],
    data: {
        pageTitle: 'nameview.pageTitle'
    }
};

export const hostedAdditionalCaseInfoState: Ng2StateDeclaration = {
    name: 'hostedAdditionalCaseInfoPopup',
    url: '/hosted/additionalCaseInfo/:id?:restrictOnWip:hostId',
    component: HostedComponent,
    params: {
        id: {
            type: 'int'
        },
        hostId: '',
        restrictOnWip: ''
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            }
        ]
};

export const hostedCaseAttachmentMaintenanceState: Ng2StateDeclaration = {
    name: 'hostedCaseAttachmentMaintenance',
    url: '/hosted/attachmentMaintenance/case/:caseId?:hostId:activityKey:sequenceKey:actionKey:eventKey:eventCycle',
    component: HostedComponent,
    params: {
        caseId: {
            type: 'int'
        },
        hostId: '',
        activityKey: {
            type: 'int'
        },
        sequenceKey: {
            type: 'int'
        },
        eventKey: '',
        eventCycle: '',
        actionKey: ''
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            }
        ],
    data: {
        pageTitle: 'attachmentMaintenance.pageTitle'
    }
};
export const hostedNameAttachmentMaintenanceState: Ng2StateDeclaration = {
    name: 'hostedNameAttachmentMaintenance',
    url: '/hosted/attachmentMaintenance/name/:nameId?:hostId:activityKey:sequenceKey',
    component: HostedComponent,
    params: {
        nameId: {
            type: 'int'
        },
        hostId: '',
        activityKey: {
            type: 'int'
        },
        sequenceKey: {
            type: 'int'
        }
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            }
        ],
    data: {
        pageTitle: 'attachmentMaintenance.pageTitle'
    }
};
export const hostedActivityAttachmentMaintenanceState: Ng2StateDeclaration = {
    name: 'hostedActivityAttachmentMaintenance',
    url: '/hosted/attachmentMaintenance/activity?:hostId:activityKey:sequenceKey',
    component: HostedComponent,
    params: {
        hostId: '',
        activityKey: {
            type: 'int'
        },
        sequenceKey: {
            type: 'int'
        }
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            }
        ],
    data: {
        pageTitle: 'attachmentMaintenance.pageTitle'
    }
};

export const hostedStartTimerForCaseState: Ng2StateDeclaration = {
    name: 'hostedStartTimerForCase',
    url: '/hosted/startTimerFor/case?:hostId:caseKey',
    component: HostedComponent,
    params: {
        hostId: '',
        caseKey: {
            type: 'int'
        }
    },
    resolve: [
        {
            token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
        }
    ]
};

export const hostedGenerateDocumentState: Ng2StateDeclaration = {
    name: 'hostedGenerateDocument',
    url: '/hosted/generateDocument?:isCase?:isWord?:isE2e?:caseKey?:nameKey?:nameCode?:irn?:hostId',
    component: HostedComponent,
    params: {
        hostId: '',
        isCase: {
            type: 'bool',
            default: false
        },
        isWord: {
            type: 'bool',
            default: false
        },
        caseKey: {
            type: 'int'
        },
        nameKey: {
            type: 'int'
        },
        nameCode: '',
        irn: '',
        isE2e: {
            type: 'bool',
            default: true
        }
    },
    resolve:
        [
            {
                token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
            }
        ],
    data: {
        pageTitle: ''
    }
};

export const hostedTimerWidgetState: Ng2StateDeclaration = {
    name: 'hostedTimerWidget',
    url: '/hosted/timerWidget?:hostId',
    component: HostedComponent,
    params: {
        hostId: ''
    },
    resolve: [
        {
            token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
        }
    ]
};

export const hostedAdjustWipState: Ng2StateDeclaration = {
    name: 'hostedAdjustWip',
    url: '/hosted/adjustWip?:entityKey:transKey:wipSeqKey:hostId',
    component: HostedComponent,
    params: {
        entityKey: {
            type: 'int'
        },
        transKey: {
            type: 'int'
        },
        wipSeqKey: {
            type: 'int'
        },
        hostId: ''
    },
    resolve: [
        {
            token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
        }
    ]
};

export const hostedSplitWipState: Ng2StateDeclaration = {
    name: 'hostedSplitWip',
    url: '/hosted/splitWip?:entityKey:transKey:wipSeqKey:hostId',
    component: HostedComponent,
    params: {
        entityKey: {
            type: 'int'
        },
        transKey: {
            type: 'int'
        },
        wipSeqKey: {
            type: 'int'
        },
        hostId: ''
    },
    resolve: [
        {
            token: 'stateParams', deps: [Transition], resolveFn: getStateParameters
        }
    ]
};