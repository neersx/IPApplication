export class SplitWipItem {
  id: number;
  name: any;
  case?: any;
  staff?: any;
  profitCentre: any;
  localValue: number;
  foreignValue?: number;
  exchRate?: number;
  splitPercent: number;
  narrative: any;
  currency?: string;
  debitNoteText?: string;
}

export class SplitWipData {
  entityKey: number;
  transKey: number;
  wipSeqKey: number;
  transDate: Date;
  wipCode: string;
  wipCategoryCode: string;
  wipDescription: string;
  responsibleName: string;
  responsibleNameCode: string;
  caseKey?: number;
  caseReference?: string;
  staffKey?: number;
  staffName?: string;
  staffCode?: string;
  balance?: number;
  isCreditWip: boolean;
  narrativeKey?: number;
  debitNoteText?: string;
  acctClientKey?: number;
  localAmount?: number;
  foreignBalance?: number;
  localValue?: number;
  foreignValue?: number;
  localCurrency?: string;
  foreignCurrency?: string;
  exchRate?: number;
  localDeciamlPlaces: number;
  foreignDecimalPlaces?: number;
  productCode?: number;
  empProfitCentre?: string;
  empProfitCentreDescription?: string;
  wpProfitCentreSource?: string;
  logDateTimeStamp?: Date;
  narrativeCode?: string;
  narrativeTitle?: string;
  wipProfitCentreSource?: number;
  profitCentreKey?: string;
  profitCentreDescription?: string;
}

export enum SplitWipType {
  amount,
  equally,
  percentage
}

export class SplitWipArray {
  entities: any;

  constructor() {
    this.entities = [];
  }

  getServerReady = (data: Array<SplitWipItem>, originalWipItem: SplitWipData, reasonCode: string, isWarningSuppressed: boolean) => {
    data.forEach(wip => {
      const formData = {
        entity: {
          entityKey: originalWipItem.entityKey,
          transKey: originalWipItem.transKey,
          wipSeqKey: originalWipItem.wipSeqKey,
          transDate: originalWipItem.transDate,
          wipCode: originalWipItem.wipCode,
          caseKey: wip.case ? wip.case.key : null,
          nameKey: wip.name ? wip.name.key : null,
          staffKey: wip.staff ? wip.staff.key : null,
          profitCentreKey: wip.profitCentre ? wip.profitCentre.code : null,
          narrativeKey: wip.narrative ? wip.narrative.key : null,
          debitNoteText: wip.debitNoteText,
          localAmount: wip.localValue,
          foreignAmount: originalWipItem.foreignCurrency ? wip.foreignValue : null,
          uniqueKey: wip.id,
          splitPercentage: wip.splitPercent,
          isCreditWip: originalWipItem.isCreditWip,
          reasonCode
        },
        isWarningSuppressed
      };
      this.entities.push(formData);
    });
  };
}
