export interface HostChildComponent {

    onChangeAction: any;
    onNavigationAction: any;
    setOnHostNavigation(payload: any, then: (val: any) => any): void;
    setOnChangeAction(payload: any, then: (val: any) => any): void;
    removeOnChangeAction(): void;
}
