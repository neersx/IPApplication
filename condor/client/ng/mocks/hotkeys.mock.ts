export class HotKeysMock {
    get = jest.fn().mockReturnValue([]);
    add = jest.fn().mockImplementation((data): any => {
        this.addedKeys.push(data);

        return data;
    });
    hotkeys: any;
    remove = jest.fn();

    addedKeys: Array<any> = new Array<any>();
}