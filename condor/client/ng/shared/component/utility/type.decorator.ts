const TYPE_MAP = new Map<string, any>();

// tslint:disable: only-arrow-functions
export function TypeDecorator(typeName: string): any {
    // tslint:disable: only-arrow-functions
    return function _TypeDecorator<T>(constr: T): any {
        TYPE_MAP.set(typeName, constr);
    };
}

export function getComponent(typeName: string): any {
    const component = TYPE_MAP.get(typeName);
    if (!component) {
        throw new Error(`Picklist Maintenance Component does not contain the decorator @TypeDecorator('${typeName}')`);
    }

    return component;
}