import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';

@Component({
  selector: 'test-qr-code',
  templateUrl: './qrcodetest.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class QRCodeTestComponent implements OnInit {
  qrCodeValue: string;
  ngOnInit(): void {
      this.qrCodeValue = 'Test QR Code';
  }
}
