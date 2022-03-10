using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Extensions;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Presentation
{

    public class BillLine
    {
        public int ItemEntityId { get; set; }
        public int ItemTransactionId { get; set; }
        public int ItemLineNo { get; set; }
        public string WipCode { get; set; }
        public string WipTypeId { get; set; }
        public string CategoryCode { get; set; }
        public string CaseRef { get; set; }
        public decimal? Value { get; set; }
        public short DisplaySequence { get; set; }
        public DateTime? PrintDate { get; set; }
        public string PrintName { get; set; }
        public decimal? PrintChargeOutRate { get; set; }
        public short? PrintTotalUnits { get; set; }
        public short? UnitsPerHour { get; set; }
        public short? NarrativeId { get; set; }
        public string Narrative { get; set; }
        public decimal? ForeignValue { get; set; }
        public string PrintChargeCurrency { get; set; }
        public string BillingCurrency { get; set; }

        public string PrintTime { get; set; }
        public decimal? LocalTax { get; set; }
        public int? StaffKey { get; set; }
        public string TaxCode { get; set; }
        public string GeneratedFromTaxCode { get; set; }
        public bool? IsHiddenForDraft { get; set; }
        public ICollection<BillLineWip> WipItems { get; set; } = new Collection<BillLineWip>();
    }

    public static class BillLineExtensions
    {
        public static void ReverseSigns(this BillLine billLine)
        {
            billLine.Value *= -1;
            billLine.ForeignValue *= -1;
            billLine.LocalTax *= -1;
        }

        public static XElement AsXml(this BillLine billLine)
        {
            return new XElement("BillLine",
                                new XElement("BillLineNo", billLine.ItemLineNo),
                                new XElement("WIPCode", billLine.WipCode),
                                new XElement("WIPTypeId", billLine.WipTypeId),
                                new XElement("WIPCategory", billLine.CategoryCode),
                                new XElement("NarrativeCode", billLine.NarrativeId),
                                new XElement("StaffKey", billLine.StaffKey),
                                new XElement("CaseIRN", billLine.CaseRef)
                               );
        }

        public static (string ShortNarrative, string LongNarrative) SplitNarrative(this BillLine billLine)
        {
            if (billLine == null) throw new ArgumentNullException(nameof(billLine));

            var r = billLine.Narrative.SplitByLength();

            return (r.ShortText, r.LongText);
        }
    }

    public static class BillLinesExtensions
    {
        public static XElement AsXml(this IEnumerable<BillLine> billLines)
        {
            return new XElement("BillLines", billLines.Select(_ => _.AsXml()));
        }
    }
}