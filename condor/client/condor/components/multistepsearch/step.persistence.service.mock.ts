module inprotech.components.multistepsearch {

    export interface IStepsPersistenceServiceMock {
        getExistingTopicFormData: any;
        getStepTopicData(stepId);
        initTopicsFormData();
        persistDefaultOptions();
    }

    export class StepsPersistenceServiceMock implements IStepsPersistenceServiceMock {
        public steps: Array<any>;
        public topicOptions: Array<any>;
        public topicsFormData: Array<any>;

        constructor() {
            this.steps = [];
            this.topicOptions = [];
            this.topicsFormData = [];
            spyOn(this, 'getStepTopicData').and.callThrough();
            spyOn(this, 'initTopicsFormData').and.callThrough();
            spyOn(this, 'persistDefaultOptions').and.callThrough();
            spyOn(this, 'applyStepData').and.callThrough();
        }

        getStepTopicData = (stepId) => {
            return [{
                topicKey: 'topic',
                formData: {
                    caseReference: '1234/a',
                    propertyType: 'Patent'
                }
            }];
        }

        initTopicsFormData = () => {
            return {};
        }

        persistDefaultOptions = () => {
            return {};
        }

        getExistingTopicFormData = (key) => {
            let defaultFormData = this.topicViewModel();
            let topicData = _.first(_.filter(defaultFormData, function (data: any) {
                return data.topicKey === key;
            }))

            return topicData.formData;
        }

        applyStepData = (selectedStep, topics, steps) => {
            return {};
        }

        topicViewModel = (): any => {

            let viewModel = [{
                topicKey: 'Details',
                formData: {
                    id: '1',
                    caseOfficeOperator: '0',
                    caseTypeOperator: '0',
                    jurisdictionOperator: '0',
                    includeDraftCases: false,
                    includeWhereDesignated: false,
                    includeGroupMembers: false,
                    propertyTypeOperator: '0',
                    caseCategoryOperator: '0',
                    subTypeOperator: '0',
                    basisOperator: '0',
                    classOperator: '2',
                    local: true,
                    international: false
                }
            }, {
                topicKey: 'Text',
                formData: {
                    id: '1',
                    typeOfMarkOperator: '0',
                    titleMarkOperator: '2',
                    textTypeOperator: '2',
                    keywordOperator: '0'
                }
            },
            {
                topicKey: 'designElement',
                formData: {
                    firmElementOperator: '2',
                    clientElementOperator: '2',
                    officialElementOperator: '2',
                    registrationNoOperator: '2',
                    typefaceOperator: '2',
                    elementDescriptionOperator: '2',
                    isRenew: false
                }
            },
            {
                topicKey: 'eventsActions',
                formData: {
                    eventOperator: 'sd',
                    importanceLevelOperator: '7',
                    eventDatesOperator: '7',
                    actionOperator: '0',
                    eventNotesOperator: '4',
                    eventNoteTypeOperator: '0',
                    occurredEvent: true,
                    dueEvent: false,
                    includeClosedActions: false,
                    isRenewals: true,
                    isNonRenewals: true,
                    actionIsOpen: false,
                    eventWithinValue: {
                        type: 'D',
                        value: 0
                    }
                }
            },
            {
                topicKey: 'Names',
                formData: {
                    id: '1',
                    instructorOperator: '0',
                    ownerOperator: '0',
                    agentOperator: '0',
                    staffOperator: '0',
                    signatoryOperator: '0',
                    namesOperator: '0',
                    isSignatoryMyself: false,
                    isStaffMyself: false,
                    inheritedNameTypeOperator: '0',
                    parentNameOperator: '0',
                    defaultRelationshipOperator: '0'
                }
            },
            {
                topicKey: 'otherDetails',
                formData: {
                    fileLocationOperator: '0',
                    bayNoOperator: '2',
                    purchaseOrderNoOperator: '2',
                    includeInherited: false,
                    forInstructionOperator: '0',
                    forInstruction: true,
                    forCharacteristicOperator: '0',
                    instructorOperatorGroup: 'EqualExist',
                    policingIncomplete: false,
                    globalNameChangeIncomplete: false,
                    letters: false,
                    charges: false
                }
            },
            {
                topicKey: 'patentTermAdjustments',
                formData: {
                    suppliedPtaOperator: '7',
                    determinedByUsOperator: '7',
                    ipOfficeDelayOperator: '7',
                    applicantDelayOperator: '7',
                    ptaDiscrepancies: null,
                    fromSuppliedPta: null,
                    toSuppliedPta: null,
                    fromPtaDeterminedByUs: null,
                    toPtaDeterminedByUs: null,
                    fromIpOfficeDelay: null,
                    toIpOfficeDelay: null,
                    fromApplicantDelay: null,
                    toApplicantDelay: null
                }
            },
            {
                topicKey: 'References',
                formData: {
                    yourReferenceOperator: '2',
                    caseReferenceOperator: '2',
                    officialNumberOperator: '0',
                    caseNameReferenceType: 'I',
                    caseNameReferenceOperator: '2',
                    familyOperator: '0',
                    caseListOperator: '0',
                    searchNumbersOnly: false,
                    searchRelatedCases: false,
                    isPrimeCasesOnly: 0
                }
            },
            {
                topicKey: 'Status',
                formData: {
                    isPending: true,
                    isRegistered: true,
                    isDead: false,
                    caseStatusOperator: '0',
                    renewalStatusOperator: '0'
                }
            },
            {
                topicKey: 'attributes',
                formData: {
                    id: '1',
                    attribute1: {
                        attributeOperator: '0'
                    },
                    attribute2: {
                        attributeOperator: '0'
                    },
                    attribute3: {
                        attributeOperator: '0'
                    },
                    booleanAndOr: 0
                }
            }, {
                topicKey: 'dataManagement',
                formData: {
                    id: '1'
                }
            }
            ]
            return viewModel;
        }
    }

    angular.module('inprotech.mocks.components.multistepsearch')
        .service('StepsPersistenceServiceMock', StepsPersistenceServiceMock);
}