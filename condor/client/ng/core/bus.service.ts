import { Injectable } from '@angular/core';
declare var radio: any; // from 'radio';

@Injectable()
export class BusService {

  channel = (channel: any) => {
    return radio(channel);
  };

  singleSubscribe = (channel: any, callback: any) => {
    radio().channels[channel] = [];
    radio(channel).subscribe(callback);
  };
}
