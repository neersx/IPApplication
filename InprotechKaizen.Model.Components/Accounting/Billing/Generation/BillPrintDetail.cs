using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation
{
    public class BillPrintDetail
    {
        public int CopyNo { get; set; }
        public BillPrintType BillPrintType { get; set; }
        public string OpenItemNo { get; set; }
        public string EntityCode { get; set; }
        public string BillTemplate { get; set; }
        public string ReprintLabel { get; set; }
        public string CopyLabel { get; set; }
        public string CopyToName { get; set; }
        public string CopyToAttention { get; set; }
        public string CopyToAddress { get; set; }
        public bool IsPdfModifiable { get; set; }

        public bool ExcludeFromConcatenation { get; set; }
    }

    public static class BillPrintDetailExt
    {
        static readonly BillPrintDetailComparer Comparer = new BillPrintDetailComparer();

        public static IEnumerable<BillPrintDetail> InPrintOrder(this IEnumerable<BillPrintDetail> billPrintDetails)
        {
            return billPrintDetails.OrderBy(_ => _, Comparer);
        }

        public static IEnumerable<BillPrintDetail> FinalisedInvoicePrintType(this IEnumerable<BillPrintDetail> billPrintDetails)
        {
            return billPrintDetails.Where(b => b.BillPrintType == BillPrintType.FinalisedInvoice);
        }

        public static IEnumerable<BillPrintDetail> CustomerRequestedInvoiceCopiesPrintType(this IEnumerable<BillPrintDetail> billPrintDetails)
        {
            return billPrintDetails.Where(b => b.BillPrintType == BillPrintType.CustomerRequestedInvoiceCopies);
        }
    }

    public enum BillPrintType
    {
        DraftInvoice = 0,
        FinalisedInvoice = 1,
        FinalisedInvoiceWithoutReprintLabel = 2,
        FinalisedInvoiceWithReprintLabel = 3,
        CopyToInvoice = 4,
        CustomerRequestedInvoiceCopies = 5,
        FirmInvoiceCopy = 6
    }

    class BillPrintDetailComparer : IComparer<BillPrintDetail>
    {
        public int Compare(BillPrintDetail x, BillPrintDetail y)
        {
            if (x == null || y == null) return 1;
            if (x.BillPrintType == y.BillPrintType)
            {
                return 0;
            }
            if ((int) x.BillPrintType > (int) y.BillPrintType)
            {
                return -1;
            }
            return 1;
        }
    }
}
