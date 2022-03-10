using System;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{

    public class DebtorOpenItemNo
    {
        public DebtorOpenItemNo()
        {
            
        }

        public DebtorOpenItemNo(int debtorId)
        {
            DebtorId = debtorId;
        }

        public string OpenItemNo { get; set; }
        public int DebtorId { get; set; }
        public DateTime? LogDateTimeStamp { get; set; }
        public Decimal? OfficeItemNoTo { get; set; }
        public string OfficeDescription { get; set; }
    }
}