using Aspose.Cells;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using System;
using System.Collections.Generic;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public static class PaperSizeConvertor
    {
        static readonly Dictionary<ReportExportFormat, Func<PaperSize, dynamic>> _ = new Dictionary
            <ReportExportFormat, Func<PaperSize, dynamic>>
            {
                {ReportExportFormat.Excel, ExcelConvertor},
                {ReportExportFormat.Word, WordConvertor}
            };

        public static PaperSizeType ForExcel(PaperSize paperSize)
        {
            return _[ReportExportFormat.Excel](paperSize);
        }

        public static Aspose.Words.PaperSize ForWord(PaperSize paperSize)
        {
            return _[ReportExportFormat.Word](paperSize);
        }

        static dynamic ExcelConvertor(PaperSize paperSize)
        {
            var value = PaperSizeType.PaperA4;
            switch (paperSize)
            {
                case PaperSize.A3:
                    value = PaperSizeType.PaperA3;
                    break;
                case PaperSize.A4:
                case PaperSize.Default:
                    value = PaperSizeType.PaperA4;
                    break;
                case PaperSize.A5:
                    value = PaperSizeType.PaperA5;
                    break;
                case PaperSize.B4:
                    value = PaperSizeType.PaperB4;
                    break;
                case PaperSize.B5:
                    value = PaperSizeType.PaperB5;
                    break;
                case PaperSize.Executive:
                    value = PaperSizeType.PaperExecutive;
                    break;
                case PaperSize.Folio:
                    value = PaperSizeType.PaperFolio;
                    break;
                case PaperSize.Ledger:
                    value = PaperSizeType.PaperLedger;
                    break;
                case PaperSize.Legal:
                    value = PaperSizeType.PaperLegal;
                    break;
                case PaperSize.Letter:
                    value = PaperSizeType.PaperLetter;
                    break;
                case PaperSize.EnvelopeDL:
                    value = PaperSizeType.PaperEnvelopeDL;
                    break;
                case PaperSize.Quarto:
                    value = PaperSizeType.PaperQuarto;
                    break;
                case PaperSize.Statement:
                    value = PaperSizeType.PaperStatement;
                    break;
                case PaperSize.Tabloid:
                    value = PaperSizeType.PaperTabloid;
                    break;
                case PaperSize.Paper10x14:
                    value = PaperSizeType.Paper10x14;
                    break;
                case PaperSize.Paper11x17:
                    value = PaperSizeType.Paper11x17;
                    break;
            }
            return value;
        }

        static dynamic WordConvertor(PaperSize paperSize)
        {
            var value = Aspose.Words.PaperSize.A4;
            switch (paperSize)
            {
                case PaperSize.A3:
                    value = Aspose.Words.PaperSize.A3;
                    break;
                case PaperSize.Default:
                case PaperSize.A4:
                    value = Aspose.Words.PaperSize.A4;
                    break;
                case PaperSize.A5:
                    value = Aspose.Words.PaperSize.A5;
                    break;
                case PaperSize.B4:
                    value = Aspose.Words.PaperSize.B4;
                    break;
                case PaperSize.B5:
                    value = Aspose.Words.PaperSize.B5;
                    break;
                case PaperSize.Executive:
                    value = Aspose.Words.PaperSize.Executive;
                    break;
                case PaperSize.Folio:
                    value = Aspose.Words.PaperSize.Folio;
                    break;
                case PaperSize.Ledger:
                    value = Aspose.Words.PaperSize.Ledger;
                    break;
                case PaperSize.Legal:
                    value = Aspose.Words.PaperSize.Legal;
                    break;
                case PaperSize.Letter:
                    value = Aspose.Words.PaperSize.Letter;
                    break;
                case PaperSize.EnvelopeDL:
                    value = Aspose.Words.PaperSize.EnvelopeDL;
                    break;
                case PaperSize.Quarto:
                    value = Aspose.Words.PaperSize.Quarto;
                    break;
                case PaperSize.Statement:
                    value = Aspose.Words.PaperSize.Statement;
                    break;
                case PaperSize.Tabloid:
                    value = Aspose.Words.PaperSize.Tabloid;
                    break;
                case PaperSize.Paper10x14:
                    value = Aspose.Words.PaperSize.Paper10x14;
                    break;
                case PaperSize.Paper11x17:
                    value = Aspose.Words.PaperSize.Paper11x17;
                    break;
            }
            return value;
        }
    }
}
