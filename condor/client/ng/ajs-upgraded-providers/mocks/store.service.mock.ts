export class StoreServiceMock {
    local = {
        get(id: string): boolean {
            return true;
        },
        default(id: string, value: any): void { return; }
    };
}
