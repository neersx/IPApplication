export interface ValidationError {
    warningFlag: boolean;
    topic: string;
    field: string;
    id: any;
    message: string;
    customValidationMessage?: string;
    displayMessage: boolean;
    severity: 'warning' | 'error';
    customData: any;
}
