export class IpxNotificationConfig {
    constructor(
        public type = NotificationType.confirmOk,
        public size = '',
        public title = '',
        public message = '',
        public isAlertWindow?: boolean,
        public isWarningWindow?: boolean,
        public messageParams?: any,
        public errors?: Array<any>,
        public warnings?: Array<any>,
        public confirmText?: string,
        public cancelText?: string,
        public animated?: boolean,
        public showCheckbox?: boolean,
        public checkboxLabel?: string,
        public isChecked?: boolean,
        public createCopy?: string
    ) {
    }
}

export enum NotificationType {
    Info,
    confirmOk,
    confirmDelete,
    alert,
    discard,
    policing,
    sanityCheck,
    adhocMaintenance,
    list
}
