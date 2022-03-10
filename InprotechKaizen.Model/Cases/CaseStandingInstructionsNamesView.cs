using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASESTANDINGINSTRUCTIONNAMES_VIEW")]
    public class CaseStandingInstructionsNamesView
    {
        [Obsolete("This is a database view")]
        public CaseStandingInstructionsNamesView()
        {
        }

        [Key]
        [Column("CASEID", Order = 1)]
        public int CaseId { get; set; }

        [Key]
        [MaxLength(3)]
        [Column("NAMETYPE", Order = 2)]
        public string NameTypeCode { get; set; }

        [Key]
        [Column("NAMENO", Order = 3)]
        public int NameId { get; set; }

    }
}