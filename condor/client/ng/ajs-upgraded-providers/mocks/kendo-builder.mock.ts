export class KendoBuilderMock {
    r = {
        buildOptions(scope, options): any {
            const data = (): any =>
                [];
            const r2 = {
                search(): any {
                    return {
                        then(cb: any): void {
                            cb();
                        }
                    };
                },
                $read(): void {
                    return;
                }
            };

            return r2;
        }
    };
}
