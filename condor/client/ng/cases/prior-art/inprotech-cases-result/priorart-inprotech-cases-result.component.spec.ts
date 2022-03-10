import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { DataItemPicklistComponent } from 'shared/component/typeahead/ipx-picklist/ipx-picklist-modal-maintenance/data-item-picklist/data-item-picklist.component';
import { PriorArtSearch, PriorArtSearchType } from '../priorart-search/priorart-search-model';
import { PriorArtServiceMock } from '../priorart.service.mock';
import { PriorartInprotechCasesResultComponent } from './priorart-inprotech-cases-result.component';

describe('PriorartSearchResultComponent', () => {
  let notificationServiceMock: IpxNotificationServiceMock;
  let cdRef: ChangeDetectorRefMock;
  const serviceMock = new PriorArtServiceMock();
  let successNotificationServiceMock: NotificationServiceMock;
  let component: PriorartInprotechCasesResultComponent;
  let localSettings: any;
  const data: any = {
    result: [{
        errors: false,
        matches: [{
            id: 1
        },
        {
            id: 2
        }],
      message: 'aaa',
      source: 'IpOneDataDocumentFinder'
    },
    {
        errors: false,
        matches: [{
            id: 1
        }],
      message: 'bbb',
      source: 'CaseEvidenceFinder'
    },
    {
        errors: false,
        matches: [{
            id: 1
        },
        {
            id: 2
        },
        {
            id: 3
        }],
      message: 'ccc',
      source: 'ExistingPriorArtFinder'
    }]
};

  beforeEach(() => {
    notificationServiceMock = new IpxNotificationServiceMock();
    successNotificationServiceMock = new NotificationServiceMock();
    cdRef = new ChangeDetectorRefMock();
    localSettings = new LocalSettingsMock();
    component = new PriorartInprotechCasesResultComponent(serviceMock as any, notificationServiceMock as any, successNotificationServiceMock as any, cdRef as any, localSettings);
    component.data = data;
  });

  it('should create and initialise the component', () => {
    component.ngOnInit();
    expect(component).toBeDefined();
    expect(component.gridOptions).toBeDefined();
  });

  it('should import the data when import basic details', () => {
    const dataItem = {
      abstract: 'abby stract',
      countryCode: 'AU',
      officialNumber: '777777',
      reference: 'ref',
      kind: 'BB',
      applicationDate: null,
      caseStatus: 'A',
      citation: 'citation Import',
      comments: 'comments Import',
      countryName: 'country Import',
      description: 'description Import',
      id: 12,
      hasChanges: true,
      imported: false,
      isComplete: true,
      name: 'name Import',
      origin: 'origin Import',
      grantedDate: null,
      priorityDate: null,
      ptoCitedDate: null,
      publishedDate: null,
      refDocumentParts: 'ref Import',
      referenceLink: 'link Import',
      title: 'title Import',
      translation: 'translation Import',
      type: 'type Import'
    };
    const priorArtSearch = new PriorArtSearch();
    priorArtSearch.caseKey = 555;
    priorArtSearch.officialNumber = '777778';
    priorArtSearch.country = 'AU';
    priorArtSearch.sourceDocumentId = 667;
    serviceMock.existingPriorArt$.mockReturnValue(of({
        result: false
    }));
    component.searchData = priorArtSearch;
    component.ngOnInit();
    component.import(dataItem);

    expect(serviceMock.existingPriorArt$).toHaveBeenCalledWith(dataItem.countryCode, dataItem.officialNumber, dataItem.kind);
    expect(dataItem.hasChanges).toBeFalsy();
    expect(dataItem.imported).toBeTruthy();
    delete dataItem.hasChanges;
    delete dataItem.imported;
    expect(serviceMock.importCase$).toHaveBeenCalledWith({
      evidence: dataItem,
      country: dataItem.countryCode,
      officialNumber: dataItem.officialNumber,
      sourceDocumentId: priorArtSearch.sourceDocumentId,
      caseKey: priorArtSearch.caseKey,
      source: PriorArtSearchType.IpOneDataDocumentFinder
    });
  });

  it('should ask for user to proceed when prior already exists while importing', () => {
    const dataItem = {
      abstract: 'abby stract',
      countryCode: 'AU',
      officialNumber: '777777',
      reference: 'ref',
      kind: 'BB'
    };
    const priorArtSearch = new PriorArtSearch();
    priorArtSearch.caseKey = 555;
    priorArtSearch.officialNumber = '77777';
    priorArtSearch.country = 'AU';
    serviceMock.existingPriorArt$.mockReturnValue(of ({
        result: true
    }));
    component.searchData = priorArtSearch;
    component.ngOnInit();
    component.import(dataItem);

    expect(notificationServiceMock.openConfirmationModal).toHaveBeenCalled();
  });
});