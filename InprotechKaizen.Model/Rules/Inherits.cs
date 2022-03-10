using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Rules
{
    [Table("INHERITS")]
    public class Inherits
    {
        [Obsolete("For persistence only.")]
        public Inherits()
        {
        }

        public Inherits(int childCriteriaNo, int parentCriteriaNo)
        {
            CriteriaNo = childCriteriaNo;
            FromCriteriaNo = parentCriteriaNo;
        }

        [Key]
        [Column("CRITERIANO", Order = 1)]
        public int CriteriaNo { get; internal set; }

        [Key]
        [Column("FROMCRITERIA", Order = 2)]
        public int FromCriteriaNo { get; internal set; }

        [ForeignKey("CriteriaNo")]
        public virtual Criteria Criteria { get; set; }

        [ForeignKey("FromCriteriaNo")]
        public virtual Criteria FromCriteria { get; set; }
    }
}
