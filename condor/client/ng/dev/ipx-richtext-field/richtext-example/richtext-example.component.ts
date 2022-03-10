import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';

@Component({
  selector: 'richtext-example',
  templateUrl: './richtext-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RichtextExampleComponent {

  richText = 'Rich <b>Text</b>';
  plainText = 'Plain Text';

  onRichTextChange = (event: Event) => {
    console.log('richTextChange');
    console.log(event);
  };

  onPlainTextChange = (event: Event) => {
    console.log('richTextChange');
    console.log(event);
  };

}
