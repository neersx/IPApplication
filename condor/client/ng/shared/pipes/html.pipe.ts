import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'html'
})
export class HtmlPipe implements PipeTransform {

  transform(value: any, args?: any): any {
    const carriageToReplace = new RegExp('(\r\n|\n\r|\n|\r)', 'g'); // eslint-disable-line no-control-regex
    if (value && value.match(carriageToReplace)) {
      return value.replace(carriageToReplace, '<br/>');
    }

    return value;
  }
}
