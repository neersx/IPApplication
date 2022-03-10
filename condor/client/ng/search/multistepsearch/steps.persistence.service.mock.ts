import { SearchOperator } from 'search/common/search-operators';
import * as _ from 'underscore';
import { TopicData } from './ipx-step.model';
import { IStepsPersistenceService } from './steps.persistence.service';

export class StepsPersistanceSeviceMock implements IStepsPersistenceService {

  steps: Array<any>;
  defaultTopicsData: Array<TopicData>;

  constructor() {
    spyOn(this, 'getTopicExistingViewModel').and.callThrough();
  }

  applyStepData = jest.fn();

  getTopicExistingViewModel = (topicKey: string): TopicData => {
    return this.getTopicsDefaultViewModel(topicKey);
  };

  getTopicsDefaultViewModel(topicKey: string): TopicData {
    const defaultFormData = this.topicViewModel();
    const topicData = _.first(_.filter(defaultFormData, (data: any) => {
      return data.topicKey === topicKey;
    }));

    return topicData.formData;
  }

  private readonly topicViewModel = (): Array<TopicData> => {
    const viewModel = [{
      topicKey: 'Details',
      formData: {
        id: '1',
        caseOfficeOperator: SearchOperator.equalTo,
        caseTypeOperator: SearchOperator.equalTo,
        jurisdictionOperator: SearchOperator.equalTo,
        includeDraftCases: false,
        includeWhereDesignated: false,
        includeGroupMembers: false,
        propertyTypeOperator: SearchOperator.equalTo,
        caseCategoryOperator: SearchOperator.equalTo,
        subTypeOperator: SearchOperator.equalTo,
        basisOperator: SearchOperator.equalTo,
        classOperator: SearchOperator.equalTo,
        local: true,
        international: true
      }
    },
    {
      topicKey: 'Text',
      formData: {
        id: '1',
        typeOfMarkOperator: SearchOperator.equalTo,
        titleMarkOperator: SearchOperator.startsWith,
        textTypeOperator: SearchOperator.startsWith,
        keywordOperator: SearchOperator.equalTo,
        textType: ''
      }
    },
    {
      topicKey: 'designElement',
      formData: {
        firmElementOperator: SearchOperator.startsWith,
        clientElementOperator: SearchOperator.startsWith,
        officialElementOperator: SearchOperator.startsWith,
        registrationNoOperator: SearchOperator.startsWith,
        typefaceOperator: SearchOperator.startsWith,
        elementDescriptionOperator: SearchOperator.startsWith,
        isRenew: false
      }
    },
    {
      topicKey: 'eventsActions',
      formData: {
        eventOperator: 'sd',
        importanceLevelOperator: SearchOperator.between,
        eventDatesOperator: SearchOperator.between,
        actionOperator: SearchOperator.equalTo,
        eventNotesOperator: SearchOperator.contains,
        eventNoteTypeOperator: SearchOperator.equalTo,
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
        instructorOperator: SearchOperator.equalTo,
        ownerOperator: SearchOperator.equalTo,
        agentOperator: SearchOperator.equalTo,
        staffOperator: SearchOperator.equalTo,
        signatoryOperator: SearchOperator.equalTo,
        namesOperator: SearchOperator.equalTo,
        isSignatoryMyself: false,
        isStaffMyself: false,
        inheritedNameTypeOperator: SearchOperator.equalTo,
        parentNameOperator: SearchOperator.equalTo,
        defaultRelationshipOperator: SearchOperator.equalTo,
        namesType: '',
        isOtherCasesValue: ''
      }
    },
    {
      topicKey: 'otherDetails',
      formData: {
        fileLocationOperator: SearchOperator.equalTo,
        bayNoOperator: SearchOperator.startsWith,
        purchaseOrderNoOperator: SearchOperator.startsWith,
        includeInherited: false,
        forInstructionOperator: SearchOperator.equalTo,
        forInstruction: true,
        forCharacteristicOperator: SearchOperator.equalTo,
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
        suppliedPtaOperator: SearchOperator.between,
        determinedByUsOperator: SearchOperator.between,
        ipOfficeDelayOperator: SearchOperator.between,
        applicantDelayOperator: SearchOperator.between,
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
        yourReferenceOperator: SearchOperator.startsWith,
        caseReferenceOperator: SearchOperator.startsWith,
        officialNumberOperator: SearchOperator.equalTo,
        officialNumberType: '',
        caseNameReferenceType: 'I',
        caseNameReferenceOperator: SearchOperator.startsWith,
        familyOperator: SearchOperator.equalTo,
        caseListOperator: SearchOperator.equalTo,
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
        caseStatusOperator: SearchOperator.equalTo,
        renewalStatusOperator: SearchOperator.equalTo
      }
    },
    {
      topicKey: 'attributes',
      formData: {
        attribute1: {
          attributeOperator: SearchOperator.equalTo
        },
        attribute2: {
          attributeOperator: SearchOperator.equalTo
        },
        attribute3: {
          attributeOperator: SearchOperator.equalTo
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