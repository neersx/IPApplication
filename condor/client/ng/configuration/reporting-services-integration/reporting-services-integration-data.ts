export class ReportingServicesViewData {
    settings: ReportingServicesSetting;
}

export class ReportingServicesSetting {
    rootFolder: string;
    reportServerBaseUrl: string;
    messageSize: number;
    timeout: number;
    security: SecurityElement;
}

export class SecurityElement {
    username: string;
    password: string;
    domain: string;
}

export enum ReportingConnectionStatus {
    None,
    InProgress,
    Success,
    Failed
}