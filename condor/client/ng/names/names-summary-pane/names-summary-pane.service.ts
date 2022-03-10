import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class NamesSummaryPaneService {
  constructor(private readonly http: HttpClient) {

  }

  getName(nameId: number): Promise<NameSummaryPaneModel> {
    return this.http
      .get('api/picklists/names/' + encodeURI(nameId.toString()))
      .toPromise()
      .then((data) => {
        const nameDetailData = data as NameSummaryPaneModel;
        if (nameDetailData.dateCeased) {
          nameDetailData.ceasedDateInPast = new Date() > new Date(nameDetailData.dateCeased);
        }

        return nameDetailData;
      });
  }
}

export class NameSummaryPaneModel {
  displayName: string;
  code: string;
  debtorRestrictionFlag: boolean;
  organisationName: string;
  organisationCode: string;
  postalAddress: string;
  isExternalView: boolean;
  streetAddress: string;
  mainPhone: string;
  otherPhone: string;
  mainEmail: string;
  isIndividual: boolean;
  isStaff: boolean;
  isOrganisation: boolean;
  isSupplier: boolean;
  isClient: boolean;
  isAgent: boolean;
  mainContact: string;
  startDate: any;
  ceasedDateInPast: boolean;
  profitCenter: string;
  parentEntity: string;
  group: string;
  nationality: string;
  category: string;
  dateCeased: any;
  remarks: string;
  companyNumber: string;
  incorporated: string;
  taxNo: string;
  abbreviatedName: string;
  signOffName: string;
  informalSalutation: string;
  formalSalutation: string;
  lead?: LeadDetails;
  filesIn: string;
}

export class LeadDetails {
  leadOwner: string;
  leadStatus: string;
  leadSource: string;
  lstRevenue?: number;
  lomments?: string;
}