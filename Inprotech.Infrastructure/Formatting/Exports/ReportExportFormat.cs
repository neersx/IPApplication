using System;

namespace Inprotech.Infrastructure.Formatting.Exports
{
    public enum ReportExportFormat
    {
        Pdf = 9501,
        Word = 9502,
        Excel = 9503,
        [Obsolete]
        Xml = 9504,
        [Obsolete]
        Qrp = 9505,
        Csv = 9506,
        [Obsolete]
        Mhtml = 9507
    }
}
