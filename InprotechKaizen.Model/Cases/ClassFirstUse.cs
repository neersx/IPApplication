using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CLASSFIRSTUSE")]
    public class ClassFirstUse
    {
        [Obsolete("For persistence only.")]
        public ClassFirstUse()
        {

        }
        public ClassFirstUse(int caseId, string classId)
        {
            CaseId = caseId;
            Class = classId;
        }

        [Key]
        [Column("CASEID", Order = 0)]
        public int CaseId { get; protected set; }

        [Key]
        [MaxLength(11)]
        [Column("CLASS", Order = 1)]
        public string Class { get; protected set; }

        [Column("FIRSTUSE")]
        public DateTime? FirstUsedDate { get; set; }

        [Column("FIRSTUSEINCOMMERCE")]
        public DateTime? FirstUsedInCommerceDate { get; set; }
    }
}
