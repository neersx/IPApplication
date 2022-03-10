using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases.Events;

namespace InprotechKaizen.Model.Rules
{
    [Table("EVENTCONTROLREQEVENT")]
    public class RequiredEventRule
    {
        [Obsolete("For persistence only.")]
        public RequiredEventRule()
        {
        }

        public RequiredEventRule(ValidEvent validEvent, Event requiredEvent)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));
            if (requiredEvent == null) throw new ArgumentNullException(nameof(requiredEvent));

            CriteriaId = validEvent.CriteriaId;
            EventId = validEvent.EventId;
            RequiredEventId = requiredEvent.Id;
        }

        public RequiredEventRule(ValidEvent validEvent)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            CriteriaId = validEvent.CriteriaId;
            EventId = validEvent.EventId;
        }

        [Key]
        [Column("CRITERIANO", Order = 1)]
        public int CriteriaId { get; set; }

        [Key]
        [Column("EVENTNO", Order = 2)]
        public int EventId { get; set; }

        [Key]
        [Column("REQEVENTNO", Order = 3)]
        public int RequiredEventId { get; set; }

        [Column("INHERITED")]
        public bool Inherited { get; set; }

        public virtual ValidEvent ValidEvent { get; set; }

        [ForeignKey("RequiredEventId")]
        public virtual Event RequiredEvent { get; set; }
    }

    public static class RequiredEventRuleExt
    {
        public static RequiredEventRule InheritRuleFrom(this RequiredEventRule requiredEventRule, RequiredEventRule from)
        {
            if (requiredEventRule == null) throw new ArgumentNullException(nameof(requiredEventRule));
            if (@from == null) throw new ArgumentNullException(nameof(@from));

            requiredEventRule.Inherited = true;
            requiredEventRule.RequiredEventId = from.RequiredEventId;
            return requiredEventRule;
        }
    }
}