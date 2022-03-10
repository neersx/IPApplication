using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Rules
{
    [Table("CHECKLISTITEM")]
    public class ChecklistItem
    {
        [Obsolete("For persistence only.")]
        public ChecklistItem()
        {
        }

        [Key]
        [Column("CRITERIANO", Order = 0)]
        public int CriteriaId { get; protected set; }

        [Key]
        [Column("QUESTIONNO", Order = 1)]
        public short QuestionId { get; set; }

        [MaxLength(100)]
        [Column("QUESTION")]
        public string Question { get; set; }

        [Column("UPDATEEVENTNO")]
        public int? YesAnsweredEventId { get; set; }

        [Column("NOEVENTNO")]
        public int? NoAnsweredEventId { get; set; }

        [Column("SEQUENCENO")]
        public short? SequenceNo { get; set; }

        [Column("YESNOREQUIRED")]
        public decimal? YesNoRequired { get; set; }

        [Column("COUNTREQUIRED")]
        public decimal? CountRequired { get; set; }

        [Column("PERIODTYPEREQUIRED")]
        public decimal? PeriodTypeRequired { get; set; }

        [Column("AMOUNTREQUIRED")]
        public decimal? AmountRequired { get; set; }

        [Column("DATEREQUIRED")]
        public decimal? DateRequired { get; set; }

        [Column("EMPLOYEEREQUIRED")]
        public decimal? EmployeeRequired { get; set; }

        [Column("TEXTREQUIRED")]
        public decimal? TextRequired { get; set; }
        
        [Column("DUEDATEFLAG")]
        public decimal? DueDateFlag { get; set; }

        [Column("NODUEDATEFLAG")]
        public decimal? NoDueDateFlag { get; set; }

        [Column("YESRATENO")]
        public int? YesRateNo { get; set; }

        [Column("NORATENO")]
        public int? NoRateNo { get; set; }

        [Column("SOURCEQUESTION")]
        public short? SourceQuestion { get; set; }

        [Column("ANSWERSOURCEYES")]
        public decimal? AnswerSourceYes { get; set; }

        [Column("ANSWERSOURCENO")]
        public decimal? AnswerSourceNo { get; set; }

        [MaxLength(1)]
        [Column("PAYFEECODE")]
        public string PayFeeCode { get; set; }

        [Column("ESTIMATEFLAG")]
        public decimal? EstimateFlag { get; set; }

        [Column("DIRECTPAYFLAG")]
        public bool? DirectPayFlag { get; set; }
        [ForeignKey("CriteriaId")]
        public virtual Criteria Criteria { get; set; }
    }
}
