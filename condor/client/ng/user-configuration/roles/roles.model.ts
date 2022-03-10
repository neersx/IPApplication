export enum ObjectTable {
    MODULE,
    TASK,
    DATATOPIC
}

export enum PermissionType {
    Granted = 1,
    Denied = 2,
    NotAssigned = 3
}
export enum PermissionTypeText {
    Granted = 'Granted',
    Denied = 'Denied',
    NotAssigned = 'Not Assigned'
}
export class RoleSearch {
    roleName: string;
    description: string;
    isExternal?: boolean;
}