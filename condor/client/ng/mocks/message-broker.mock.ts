import { fn } from '@angular/compiler/src/output/output_ast';
import { of } from 'rxjs';

export class MessageBroker {
    broadcast: any;
    subscribe = jest.fn().mockImplementationOnce((a, b) => { this.broadcast =  b; });
    disconnectBindings = jest.fn();
    connect = jest.fn();
    disconnect = jest.fn();
    getConnectionId = jest.fn().mockReturnValue('555');
}