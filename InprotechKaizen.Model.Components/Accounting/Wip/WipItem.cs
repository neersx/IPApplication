using System;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public class WipItem
    {
        public int EntityKey { get; set; }

        public string Entity { get; set; }

        public int TransKey { get; set; }

        /// <summary>
        /// TODO: POST-WIP-AND-BILLING-SILVERLIGHT-REMOVAL - refactor
        /// </summary>
        public int WIPSeqKey { get; set; }

        public DateTime TransDate { get; set; }

        /// <summary>
        /// TODO: POST-WIP-AND-BILLING-SILVERLIGHT-REMOVAL - refactor
        /// </summary>
        public string WIPCode { get; set; }

        /// <summary>
        /// TODO: POST-WIP-AND-BILLING-SILVERLIGHT-REMOVAL - refactor
        /// </summary>
        public string WIPDescription { get; set; }

        public int RequestedByStaffKey { get; set; }

        public string RequestedByStaffCode { get; set; }

        public string RequestedByStaffName { get; set; }

        public int? CaseKey { get; set; }

        /// <summary>
        /// TODO: POST-WIP-AND-BILLING-SILVERLIGHT-REMOVAL - refactor
        /// </summary>
        public string IRN { get; set; }

        public string CaseReference { get; set; }

        public int? AcctClientKey { get; set; }

        public string AcctClientName { get; set; }

        public string AcctClientCode { get; set; }

        public int? StaffKey { get; set; }

        public string StaffName { get; set; }

        public string StaffCode { get; set; }

        public int ResponsibleNameKey { get; set; }
        
        public string ResponsibleNameCode { get; set; }
        
        public string ResponsibleName { get; set; }

        public string LocalCurrency { get; set; }

        /// <summary>
        /// TODO: POST-WIP-AND-BILLING-SILVERLIGHT-REMOVAL - refactor
        /// </summary>
        public int? LocalDeciamlPlaces { get; set; }

        public string ForeignCurrency { get; set; }

        public int? ForeignDecimalPlaces { get; set; }

        public decimal? ForeignValue { get; set; }

        public decimal? ExchRate { get; set; }

        public decimal LocalValue { get; set; }

        public decimal Balance { get; set; }
        
        public bool IsCreditWip { get; set; }

        public int? NarrativeKey { get; set; }

        public string NarrativeCode { get; set; }

        public string NarrativeTitle { get; set; }

        public string DebitNoteText { get; set; }

        public decimal? ForeignBalance { get; set; }

        public int? ProductCode { get; set; }

        public string ProductCodeDescription { get; set; }
        
        public string ReasonCode { get; set; }
        
        public string WipCategoryCode { get; set; }
        
        public string EmpProfitCentre { get; set; }
        
        public string EmpProfitCentreDescription { get; set; }
        
        public int WipProfitCentreSource { get; set; }

        public DateTime? LogDateTimeStamp { get; set; }

        public string DateStyle { get; set; }
    }
}