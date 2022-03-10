using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("CASECLASSITEM")]
    public class CaseClassItem
    {
        [Obsolete("For persistence only.")]
        public CaseClassItem()
        {

        }

        public CaseClassItem(int caseId, int classItemId)
        {
            CaseId = caseId;
            ClassItemId = classItemId;
        }

        [Key]
        [Column("CASEID", Order = 1)]
        public int CaseId { get; protected set; }

        [Key]
        [Column("CLASSITEMID", Order = 2)]
        public int ClassItemId { get; protected set; }
    }
}
