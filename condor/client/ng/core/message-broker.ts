import { Injectable, NgZone } from '@angular/core';
import { NGXLogger } from 'ngx-logger';
import * as _ from 'underscore';

declare var $: any;

@Injectable()
export class MessageBroker {
    private _bindings: { [bindingName: string]: (...args: Array<any>) => void } = {};
    private connection: any;
    connectionId: string;

    constructor(private readonly logger: NGXLogger, private readonly zone: NgZone) { }

    subscribe = (binding: string, callback: (...args: Array<any>) => void) => {
        if (!binding) {
            throw new Error('binding cannot be null');
        }

        this._bindings[binding] = callback;
    };

    getConnectionId = (): string => {
        if (!this.connection) {
            return null;
        }

        return this.connection.id;
    };

    connect = (): void => {
        this.zone.runOutsideAngular(() => {
            this.tryClose();
            this.connection = $.hubConnection();

            this.connection.url = 'signalr';

            const bindings = Object.keys(this._bindings).join(',');
            this.connection.qs = {
                bindings
            };

            const proxy = this.connection.createHubProxy('messageBroker');
            proxy.on('receive', (binding, data) => {
                this.zone.runOutsideAngular(() => {
                    this.logger.log('RECEIVED. arguments=', JSON.stringify(data));

                    if (this._bindings[binding]) {
                        this._bindings[binding](data);
                    }
                });
            });

            this.logger.log('CONNECTING. hub=messageBroker; bindings=', bindings);

            this.connection.disconnected(() => {
                this.zone.runOutsideAngular(() => {
                    if (this.connection.lastError) {
                        this.logger.log('DISCONNECTED. errors=', this.connection.lastError.message);
                    } else {
                        this.logger.log('DISCONNECTED');
                    }

                });
            });

            this.connection.reconnecting(() => {
                this.zone.runOutsideAngular(() => {
                    this.logger.log('RECONNECTING');
                });
            });

            this.connection.reconnected(() => {
                this.zone.runOutsideAngular(() => {
                    this.logger.log('RECONNECTED');
                });
            });

            this.connection.start({ transport: ['webSockets', 'serverSentEvents', 'longPolling'] })
                .done(() => {
                    this.zone.runOutsideAngular(() => {
                        this.logger.log('CONNECTED. connection_id=', this.connection.id);
                    });
                })
                .fail(() => {
                    this.zone.runOutsideAngular(() => {
                        this.logger.log('CONNECTION FAILED');
                    });
                });
        });
    };

    disconnect = (): Promise<void> => {
        this.tryClose();
        this._bindings = {};

        return Promise.resolve();
    };

    disconnectBindings = (bindingName: Array<string>): void => {

        if (this.connection) {
            this.connection.stop();
        }
        _.each(bindingName, (item) => {
            this.logger.log('deleting --' + item);
            if (this._bindings[item] !== undefined) {
                // tslint:disable-next-line: no-dynamic-delete
                delete this._bindings[item];
                this.logger.log('deleted --' + item);
            }
        });
        this.connect();
    };

    readonly tryClose = (): void => {
        if (this.connection) {
            this.connection.stop();
            this.connection = null;
        }
    };
}