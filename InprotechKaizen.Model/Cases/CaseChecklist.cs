using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASECHECKLIST")]
    public class CaseChecklist
    {
        [Obsolete("For persistence only.")]
        public CaseChecklist()
        {
        }

        [SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "checkList")]
        public CaseChecklist(short checkListTypeId, int caseId, short questionNo)
        {
            CheckListTypeId = checkListTypeId;
            CaseId = caseId;
            QuestionNo = questionNo;
        }

        [Key]
        [Column("CASEID", Order = 1)]
        public int CaseId { get; protected set; }

        [Key]
        [Column("QUESTIONNO", Order = 2)]
        public short QuestionNo { get; protected set; }

        [Column("CHECKLISTTYPE")]
        public short CheckListTypeId { get; set; }

        [Column("CRITERIANO")]
        public int? CriteriaId { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeId { get; set; }

        [Column("TABLECODE")]
        public int? TableCode { get; set; }

        [Column("YESNOANSWER")]
        public decimal? YesNoAnswer { get; set; }

        [Column("PRODUCTCODE")]
        public int? ProductCode { get; set; }

        [Column("PROCESSEDFLAG")]
        public decimal? ProcessedFlag { get; set; }

        [Column("CHECKLISTTEXT")]
        public string ChecklistText { get; set; }

        [Column("COUNTANSWER")]
        public int? CountAnswer { get; set; }

        [Column("VALUEANSWER")]
        public decimal? ValueAnswer { get; set; }
    }
}