using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Rules
{
    [Table("QUESTION")]
    public class Question
    {
        [Obsolete("For persistence only.")]
        public Question()
        {
        }

        public Question(short id, string questionString)
        {
            Id = id;
            QuestionString = questionString;
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("QUESTIONNO")]
        public short Id { get; private set; }

        [MaxLength(100)]
        [Column("QUESTION")]
        public string QuestionString { get; set; }

        [Column("QUESTION_TID")]
        public int? QuestionTid { get; set; }

        [Column("YESNOREQUIRED")]
        public decimal? YesNoRequired { get; set; }

        [Column("COUNTREQUIRED")]
        public decimal? CountRequired { get; set; }

        [Column("PERIODTYPEREQUIRED")]
        public decimal? PeriodTypeRequired { get; set; }

        [Column("AMOUNTREQUIRED")]
        public decimal? AmountRequired { get; set; }
        
        [Column("EMPLOYEEREQUIRED")]
        public decimal? EmployeeRequired { get; set; }

        [Column("TEXTREQUIRED")]
        public decimal? TextRequired { get; set; }

        [Column("TABLETYPE")]
        public short? TableType { get; set; }

        [MaxLength(10)]
        [Column("QUESTIONCODE")]
        public string Code { get; set; }

        [MaxLength(508)]
        [Column("INSTRUCTIONS")]
        public string Instructions { get; set; }

        [Column("INSTRUCTIONS_TID")]
        public int? InstructionsTid { get; set; }
    }
}
