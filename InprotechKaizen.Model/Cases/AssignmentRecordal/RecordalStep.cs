using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases.AssignmentRecordal
{
    [Table("RECORDALSTEP")]
    public class RecordalStep
    {
        [Key]
        [Column("CASEID", Order = 0)]
        public int CaseId { get; set; }

        [Key]
        [Column("RECORDALSTEPSEQ", Order = 1)]
        public int Id { get; set; }

        [Column("RECORDALTYPENO")]
        public int TypeId { get; set; }

        [Column("STEPNO")]
        public byte StepId { get; set; }

        [Column("MODIFIEDDATE")]
        public DateTime ModifiedDate { get; set; }
        
        public virtual RecordalType RecordalType { get; set; }
    }
}
