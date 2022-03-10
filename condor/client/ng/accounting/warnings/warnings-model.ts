import * as _ from 'underscore';

export interface Name {
    nameKey: number;
    name: string;
}

export interface CreditLimit extends Name {
    receivableBalance: number;
    creditLimit: number;
    limitPercentage?: number;
}

export interface Restriction extends Name {
    type: string;
    description: string;
    severity: string;
}

export class WipWarningData {
    budgetCheckResult?: any;
    caseWipWarnings?: Array<any>;
    prepaymentCheckResult?: any;
    billingCapCheckResult?: Array<any>;
    restrictOnWip: boolean;
}