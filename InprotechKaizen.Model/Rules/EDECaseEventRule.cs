using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases.Events;

namespace InprotechKaizen.Model.Rules
{
    [Table("EDERULECASEEVENT")]
    public class EdeCaseEventRule
    {
        [Obsolete("For persistence only.")]
        public EdeCaseEventRule()
        {
        }

        [Key]
        [Column("CRITERIANO", Order = 0)]
        public int CriteriaId { get; protected set; }

        [Key]
        [Column("EVENTNO", Order = 1)]
        public int EventId { get; set; }

        [ForeignKey("CriteriaId")]
        public virtual Criteria Criteria { get; set; }

        [ForeignKey("EventId")]
        public virtual Event Event { get; set; }
    }
}
