using System;
using System.Collections.Generic;

namespace Inprotech.Web.Cases.Details
{
    public class Overview
    {
        public int CaseKey { get; set; }
        public string Irn { get; set; }
        public string Title { get; set; }
        public string PropertyType { get; set; }
        public string Country { get; set; }
        public string CaseCategory { get; set; }
        public string SubType { get; set; }
        public string Basis { get; set; }
        public string Status { get; set; }
        public string CaseStatus { get; set; }
        public string RenewalStatus { get; set; }
        public string OfficialNumber { get; set; }
        public string Family { get; set; }
        public string CaseType { get; set; }
        public string CaseOffice { get; set; }
        public string FileLocation { get; set; }
        public string ProfitCentre { get; set; }
        public bool LocalClientFlag { get; set; }
        public List<string> HasBillPercentageDisplayed { get; set; }
        public string EntitySize { get; set; }
        public string TypeOfMark { get; set; }
        public short? NumberInSeries { get; set; }
        public NameDetail Staff { get; set; }
        public string Classes { get; set; }
        public string FirstApplicant { get; set; }
        public string Instructor { get; set; }
        public DateTime? ApplicationFilingDate { get; set; }
        public byte[] CaseImageData { get; set; }
        public int? ImageKey { get; set; }
        public string ImageDescription { get; set; }
        public bool IsRegistered { get; set; }
        public bool IsPending { get; set; }
        public bool IsDead { get; set; }
        public string PropertyTypeCode { get; set; }
        public int? PropertyTypeImageId { get; set; }
        public string PolicingStatus { get; set; }
        public bool DisplayNameVariants { get; set; }
        public string YourReference { get; set; }
        public string CaseDefaultDescription { get; set; }
        public NameDetail ClientMainContact { get; set; }
        public NameDetail OurContact { get; set; }
        public bool AllowSubClass { get; set; }
        public bool UsesDefaultCountryForClasses { get; set; }
        public bool AllowSubClassWithoutItem { get; set; }
        public bool HasAccessToAttachmentSubject { get; set; }
        public bool HasCaseEventAuditingConfigured { get; set; }
    }

    public class NameDetail
    {
        public string Name { get; set; }
        public string NameCode { get; set; }
        public int NameKey { get; set; }
        public string NameType { get; set; }
        public string ShowCode { get; set; }
    }
}