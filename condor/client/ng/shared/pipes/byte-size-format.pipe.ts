import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
    name: 'byteSizeFormat'
})

export class ByteSizeFormatPipe implements PipeTransform {
    transform(value: number, decimalPoints: number): any {
        let v = Number(value);
        let totalDivisions = 0;

        while (v >= 1024) {
            v = v / 1024;
            totalDivisions++;
        }

        return `${v.toFixed(decimalPoints || 2)} ${this.getSize(totalDivisions)}`;
    }

    private readonly getSize = (divisorCount: number) => {
        switch (divisorCount) {
            case 0: return 'B';
            case 1: return 'KB';
            case 2: return 'MB';
            case 3: return 'GB';
            case 4: return 'TB';
            default: return 'B';
        }
    };
}