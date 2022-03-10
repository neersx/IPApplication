namespace inprotech.components.multistepsearch {
  export interface IStepsPersistenceService {
    persistDefaultOptions(options): any;
    initTopicsFormData(): any;
    defaultTopicsFormData(topicKey): any;
    getTopicFormData(topicKey): any;
    getStepTopicData(stepId): any;
    resetStepData(step): any;
    applyStepData(selectedStep, topics, steps): any;
    getExistingTopicFormData(topicKey): any;
    updateOperator(index, currentOperator): any;
    getTopicFormsData(): any;
  }

  export class StepsPersistenceService implements IStepsPersistenceService {
    public steps: Array<any>;
    public topicOptions: Array<any>;
    public topicsFormData: Array<any>;

    constructor() {
      this.steps = [];
      this.topicOptions = [];
      this.topicsFormData = [];
    }

    persistDefaultOptions = options => {
      this.topicOptions = options;
    };

    initTopicsFormData = () => {
      this.topicsFormData = this.topicViewModel();
    };

    getTopicFormsData = () => {
      return this.topicViewModel();
    }

    defaultTopicsFormData = (topicKey): any => {
      let defaultFormData = this.topicViewModel();
      let topicData = _.first(
        _.filter(defaultFormData, (data: any) => {
          return data.topicKey === topicKey;
        })
      );

      return topicData.formData;
    };

    getTopicFormData = (topicKey): any => {
      let topicsFormData = this.topicsFormData;
      let topicData = _.first(
        _.filter(topicsFormData, (topicFormData: any) => {
          return topicFormData.topicKey === topicKey;
        })
      );

      return topicData.formData;
    };

    getStepTopicData = stepId => {
      let relevantStep = _.first(
        _.filter(this.steps, (step: any) => {
          return step.id === stepId;
        })
      );

      if (!relevantStep) {
        return {};
      }

      return relevantStep ? relevantStep.topicsData : {};
    };

    resetStepData = step => {
      let stepTopicsData = this.getStepTopicData(step.id);

      if (stepTopicsData) {
        _.each(stepTopicsData, (stepTopicData: any) => {
          stepTopicData.formData = this.defaultTopicsFormData(
            stepTopicData.topicKey
          );
          stepTopicData.filterData = this.defaultTopicsFormData(
            stepTopicData.topicKey
          );
        });
      }
    };

    applyStepData = (selectedStep, topics, steps) => {
      this.steps = steps;

      let relevantStep = _.first(
        _.filter(this.steps, (step: any) => {
          return step.id === selectedStep.id;
        })
      );

      if (relevantStep) {
        relevantStep.id = selectedStep.id;
        relevantStep.operator = selectedStep.operator;
        relevantStep.topicsData = this.setTopicData(topics);
      } else {
        relevantStep = {
          id: selectedStep.id,
          operator: selectedStep.operator,
          topicsData: this.setTopicData(topics)
        };
      }
    };

    getExistingTopicFormData = topicKey => {
      if (!_.any(this.steps)) {
        return this.defaultTopicsFormData(topicKey);
      }

      let topicData = _.first(
        _.filter(this.steps[0].topicsData, (stepTopicData: any) => {
          return stepTopicData.topicKey === topicKey;
        })
      );
      return topicData.formData;
    };

    updateOperator = (index, currentOperator) => {
      let step = this.steps[index];
      if (step) {
        step.operator = currentOperator;
      }
    };

    private setTopicData = topics => {
      let topicsData = [];
      _.each(topics, (topic: any) => {
        topicsData.push({
          topicKey: topic.key,
          formData: topic.formData,
          filterData: topic.getFormData()
        });
      });
      return topicsData;
    };

    private topicViewModel = () => {
      let viewModel = [
        {
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
            classOperator: '0',
            local: true,
            international: true
          }
        },
        {
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
        },
        {
          topicKey: 'dataManagement',
          formData: {}
        }
      ];
      return viewModel;
    };
  }

  angular
    .module('inprotech.components.multistepsearch')
    .service('StepsPersistenceService', StepsPersistenceService);
}
