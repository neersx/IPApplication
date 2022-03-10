using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASELISTMEMBER")]
    public class CaseListMember
    {
        [Obsolete("For persistence only.")]
        public CaseListMember()
        {
        }

        public CaseListMember(int id, int caseId, bool isPrimeCase)
        {
            Id = id;
            CaseId = caseId;
            IsPrimeCase = isPrimeCase;
        }

        public CaseListMember(int id, Case @case, bool isPrimeCase)
        {
            Id = id;
            Case = @case;
            CaseId = @case.Id;
            IsPrimeCase = isPrimeCase;
        }

        [Column("CASELISTNO", Order = 1)]
        [Key]
        public int Id { get; protected set; }

        [Column("CASEID", Order = 2)]
        [Key]
        public int CaseId { get; protected set; }

        [Column("PRIMECASE")]
        public bool IsPrimeCase { get; set; }
        
        [ForeignKey("CaseId")]
        public virtual Case Case { get; protected set; }
    }
}