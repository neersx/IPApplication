using System;

namespace Inprotech.Web.Cases.Details.DesignatedJurisdiction
{
    public class DesignatedJurisdictionData : IFileCaseViewable
    {
        public string Jurisdiction { get; set; }
        public string CountryCode { get; set; }
        public string DesignatedStatus { get; set; }
        public string OfficialNumber { get; set; }
        public string CaseStatus { get; set; }
        public string InternalReference { get; set; }
        
        public string ClientReference { get; set; }
        public DateTime? PriorityDate { get; set; }
        public string Classes { get; set; }
        public bool? IsExtensionState { get; set; }
        public string InstructorReference { get; set; }
        public string AgentReference { get; set; }
        public int? CaseKey { get; set; }
        public string Notes { get; set; }
        public bool CanView { get; set; }
        public bool IsFiled { get; set; }
        public bool CanViewInFile { get; set; }
    }
}