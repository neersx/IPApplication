import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'translate' })
export class Translate implements PipeTransform {
  transform(value: string): string {
    return value;
  }
}
