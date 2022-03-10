using System;

namespace InprotechKaizen.Model.Components.Cases.Rules.Visualisation
{
    public class EventControlDetails
    {
        public string Irn { get; set; }
        public string ActionName { get; set; }
        public int CriteriaNo { get; set; }
        public int EventNo { get; set; }
        public DateTime? EventDate { get; set; }
        public DateTime? EventDueDate { get; set; }
        public DateTime? DateRemind { get; set; }
        public string EventDescription { get; set; }
        public short? NumCyclesAllowed { get; set; }
        public string ImportanceLevel { get; set; }
        public DateTime? LogDateTimeStamp { get; set; }
        public string LoginId { get; set; }
        public string LogApplication { get; set; }
        public string Notes { get; set; }
        public string WhichDueDate { get; set; }
        public string InstructionType { get; set; }
        public string InstructionFlag { get; set; }
        public string CompareBoolean { get; set; }
        public short? ExtendPeriod { get; set; }
        public string ExtendPeriodType { get; set; }
        public bool? SaveDueDate { get; set; }
        public bool? RecalcEventDate { get; set; }
        public bool? UpdateEventImmediately { get; set; }
        public bool? UpdateWhenDue { get; set; }
        public string Status { get; set; }
        public int? PayFeeCode { get; set; }
        public string ChargeDesc { get; set; }
        public string CreateAction { get; set; }
        public string CloseAction { get; set; }
        public bool? SetThirdPartyOn { get; set; }
        public bool? SetThirdPartyOff { get; set; }
        public int? PayFeeCode2 { get; set; }
        public string ChargeDesc2 { get; set; }

    }
}
