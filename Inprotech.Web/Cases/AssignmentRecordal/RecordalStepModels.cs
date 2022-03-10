using System;
using Inprotech.Web.Picklists;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    public class CaseRecordalStep
    {
        public int CaseId { get; set; }
        public int Id { get; set; }
        public byte StepId { get; set; }
        public string StepName { get; set; }
        public RecordalTypePicklistItem RecordalType { get; set; }
        public DateTime ModifiedDate { get; set; }
        public bool IsAssigned { get; set; }
        public bool IsSelected { get; set; }
        public string Status { get; set; }
        public CaseRecordalStepElement[] CaseRecordalStepElements { get; set; }
    }

    public class CaseRecordalStepElement
    {
        public int CaseId { get; set; }
        public int Id { get; set; }
        public string StepId { get; set; }
        public int ElementId { get; set; }
        public string Element { get; set; }
        public string Label { get; set; }
        public string Value { get; set; }
        public string ValueId { get; set; }
        public string OtherValue { get; set; }
        public string OtherValueId { get; set; }
        public string EditAttribute { get; set; }
        public string NameType { get; set; }
        public int? MaxNamesAllowed { get; set; }
        public ElementType Type { get; set; }
        public string TypeText { get; set; }
        public Name[] NamePicklist { get; set; }
        public AddressPicklistItem AddressPicklist { get; set; }
        public string Status { get; set; }
        public string NameTypeValue { get; set; }
        public decimal ShowNameCode { get; set; }
    }

    public class CurrentAddress
    {
        public Name NamePicklist { get; set; }
        public AddressPicklistItem StreetAddressPicklist { get; set; }
        public AddressPicklistItem PostalAddressPicklist { get; set; }
    }

    public enum ElementType
    {
        Name,
        StreetAddress,
        PostalAddress
    }
    public static class AffectedCaseStatus
    {
        public const string Filed = "Filed";
        public const string Recorded = "Recorded";
        public const string Rejected = "Rejected";
        public const string NotYetFiled = "Not Yet Filed";
    }
}
