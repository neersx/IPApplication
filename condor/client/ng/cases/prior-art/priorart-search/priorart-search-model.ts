import { IpoSearchType, PriorArtType } from '../priorart-model';

export enum PriorArtSearchType {
  ExistingPriorArtFinder = 'ExistingPriorArtFinder',
  IpOneDataDocumentFinder = 'IpOneDataDocumentFinder',
  CaseEvidenceFinder = 'CaseEvidenceFinder'
}

export enum PriorArtOrigin {
  OriginIpOne = 'IP One Data',
  OriginInprotechPriorArt = 'Inprotech',
  OriginInprotechCase = 'Inprotech Case'
}

export class PriorArtSearchOptions {
  jurisdiction: any = {};
  applicationNo: string;
  kindCode: string;
}

export class PriorArtSearchResult {
  id: string;
  reference: string;
  citation: string;
  title: string;
  name: string;
  kind: string;
  abstract: string;
  applicationDate?: Date;
  publishedDate?: Date;
  grantedDate?: Date;
  referenceLink?: string;
  countryName?: string;
  caseKey?: number;
  sourceId?: number;
  country?: string;
  countryCode?: string;
  origin?: string;
  sourceDocumentId?: number;
  officialNumber?: string;
  priorArtStatus?: string | '';
  isCited?: boolean | false;
  priorityDate?: Date;
  ptoCitedDate?: Date;
  description: string;
  comments: string;
  refDocumentParts: string;
  translation?: number;
  isDataLoaded?: boolean;
  hasChanges?: boolean;
  publisher: string;
  city: string;

  constructor(data?: any) {
    if (!!data) {
      Object.assign(this, data);
    }
  }
}

export class PriorArtSearch {
  sourceDocumentId?: number;
  caseKey?: number;
  officialNumber: string;
  country: string;
  description: string;
  sourceId: string;
  publication: string;
  comments: string;
  countryName: string;
  kind: string;
  sourceType?: PriorArtType;
  isSourceDocument?: boolean;
  publisher: string;
  title: string;
  inventor: string;
  queryParameters?: any;
  ipoSearchType: IpoSearchType;
  multipleIpoSearch?: Array<IpoSearch>;
}

export class IpoSearch {
  country: string;
  officialNumber: string;
  kind: string;
}