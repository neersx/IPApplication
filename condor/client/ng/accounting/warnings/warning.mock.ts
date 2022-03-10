import { of } from 'rxjs';

export class WarningServiceMock {
    baseAccountingUrl = 'api/accounting';
    restrictOnWip: true;

    setPeriodTypeDescription = jest.fn().mockReturnValue('translated-period-value');
    getWarningsForNames = jest.fn();
    getCasenamesWarnings = jest.fn();
}

export class WarningCheckerServiceMock {
    performCaseWarningsCheckResult = of();
    performNameWarningsCheckResult = of();

    performCaseWarningsCheck = jest.fn().mockImplementation(() => this.performCaseWarningsCheckResult);
    performNameWarningsCheck = jest.fn().mockImplementation(() => this.performNameWarningsCheckResult);
}
