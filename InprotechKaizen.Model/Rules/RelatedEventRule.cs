using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using InprotechKaizen.Model.Cases.Events;

namespace InprotechKaizen.Model.Rules
{
    [Table("RELATEDEVENTS")]
    public class RelatedEventRule
    {
        [Obsolete("For persistence only.")]
        public RelatedEventRule()
        {
        }

        public RelatedEventRule(ValidEvent validEvent, short sequence)
        {
            if (validEvent == null) throw new ArgumentNullException(nameof(validEvent));

            CriteriaId = validEvent.CriteriaId;
            EventId = validEvent.EventId;
            Sequence = sequence;
        }

        public RelatedEventRule(int criteriaId, int eventId, short sequence)
        {
            CriteriaId = criteriaId;
            EventId = eventId;
            Sequence = sequence;
        }

        [Key]
        [Column("CRITERIANO", Order = 1)]
        public int CriteriaId { get; set; }

        [Key]
        [Column("EVENTNO", Order = 2)]
        public int EventId { get; set; }

        [Key]
        [Column("RELATEDNO", Order = 3)]
        public short Sequence { get; set; }

        [Column("RELATEDEVENT")]
        public int? RelatedEventId { get; set; }

        [Column("CLEAREVENT")]
        public decimal? ClearEvent { get; set; }

        [Column("CLEARDUE")]
        public decimal? ClearDue { get; set; }

        [Column("SATISFYEVENT")]
        public decimal? SatisfyEvent { get; set; }

        [Column("UPDATEEVENT")]
        public decimal? UpdateEvent { get; set; }

        [Column("CREATENEXTCYCLE")]
        public decimal? CreateNextCycle { get; set; }

        [MaxLength(4)]
        [Column("ADJUSTMENT")]
        public string DateAdjustmentId { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        [Column("RELATIVECYCLE")]
        public short? RelativeCycleId { get; set; }

        [Column("CLEAREVENTONDUECHANGE")]
        public bool? ClearEventOnDueChange { get; set; }

        [Column("CLEARDUEONDUECHANGE")]
        public bool? ClearDueOnDueChange { get; set; }

        public virtual ValidEvent ValidEvent { get; set; }

        public virtual Event RelatedEvent { get; set; }

        [ForeignKey("DateAdjustmentId")]
        public virtual DateAdjustment DateAdjustment { get; set; }

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited == 1; }
            set { Inherited = value ? 1 : 0; }
        }

        [NotMapped]
        public bool IsClearEvent
        {
            get { return ClearEvent == 1; }
            set { ClearEvent = value ? 1 : 0; }
        }

        [NotMapped]
        public bool IsClearDue
        {
            get { return ClearDue == 1; }
            set { ClearDue = value ? 1 : 0; }
        }

        [NotMapped]
        public bool IsSatisfyingEvent
        {
            get { return SatisfyEvent == 1; }
            set { SatisfyEvent = value ? 1 : 0; }
        }

        [NotMapped]
        public bool IsUpdateEvent
        {
            get { return UpdateEvent == 1; }
            set { UpdateEvent = value ? 1 : 0; }
        }

        [NotMapped]
        public bool IsClearEventRule => IsClearDue || IsClearEvent || ClearDueOnDueChange == true || ClearEventOnDueChange == true;

        [NotMapped]
        public int? HashKey { get; internal set; }
    }

    public static class RelatedEventRuleExt
    {
        public static int HashKey(this RelatedEventRule relatedEventRule)
        {
            if (relatedEventRule == null) throw new ArgumentNullException(nameof(relatedEventRule));

            // set once only so that the hash doesn't change when updating multi-use rules
            if (relatedEventRule.HashKey == null)
            {
                relatedEventRule.HashKey = new
                {
                    relatedEventRule.RelatedEventId,
                    relatedEventRule.RelativeCycleId,
                    ClearEvent = relatedEventRule.ClearEvent ?? 0,
                    ClearDue = relatedEventRule.ClearDue ?? 0,
                    ClearEventOnDueChange = relatedEventRule.ClearEventOnDueChange ?? false,
                    ClearDueOnDueChange = relatedEventRule.ClearDueOnDueChange ?? false,
                    relatedEventRule.SatisfyEvent,
                    relatedEventRule.UpdateEvent,
                    relatedEventRule.DateAdjustmentId
                }.GetHashCode();
            }
            return relatedEventRule.HashKey.Value;
        }

        public static IEnumerable<int> HashList(this IEnumerable<RelatedEventRule> relatedEventRules, bool inheritedOnly = false)
        {
            return relatedEventRules.Where(_ => !inheritedOnly || _.IsInherited).Select(_ => _.HashKey());
        }

        public static IEnumerable<RelatedEventRule> WhereIsSatisfyingEvent(this IEnumerable<RelatedEventRule> relatedEventRule, bool inheritedOnly = false)
        {
            return relatedEventRule.Where(_ => _.IsSatisfyingEvent && (!inheritedOnly || _.IsInherited));
        }

        public static IEnumerable<RelatedEventRule> WhereEventsToUpdate(this IEnumerable<RelatedEventRule> relatedEventRule, bool inheritedOnly = false)
        {
            return relatedEventRule.Where(_ => _.IsUpdateEvent && (!inheritedOnly || _.IsInherited));
        }

        public static IEnumerable<RelatedEventRule> WhereEventsToClear(this IEnumerable<RelatedEventRule> relatedEventRule, bool inheritedOnly = false)
        {
            return relatedEventRule.Where(_ => _.IsClearEventRule && (!inheritedOnly || _.IsInherited));
        }

        public static IQueryable<RelatedEventRule> WhereEventsToClear(this IQueryable<RelatedEventRule> relatedEventRule)
        {
            return relatedEventRule.Where(
                                          _ => _.ClearDue == 1 || _.ClearEvent == 1 || _.ClearDueOnDueChange == true || _.ClearEventOnDueChange == true
                );
        }

        public static bool IsMultiuse(this RelatedEventRule rule)
        {
            if (rule == null) throw new ArgumentNullException(nameof(rule));

            return (rule.IsClearEvent || rule.IsClearDue || rule.ClearEventOnDueChange == true || rule.ClearDueOnDueChange == true ? 1 : 0) +
                   rule.SatisfyEvent.GetValueOrDefault() +
                   rule.UpdateEvent.GetValueOrDefault() > 1;
        }

        public static bool IsDuplicateRelatedRule(this IEnumerable<RelatedEventRule> relatedEventRules, RelatedEventRule rule)
        {
            if (rule == null) throw new ArgumentNullException(nameof(rule));

            return relatedEventRules.Any(v => v.CriteriaId == rule.CriteriaId &&
                                              v.RelatedEventId == rule.RelatedEventId &&
                                              v.ClearEvent == rule.ClearEvent &&
                                              v.ClearDue == rule.ClearDue &&
                                              v.SatisfyEvent == rule.SatisfyEvent &&
                                              v.UpdateEvent == rule.UpdateEvent &&
                                              v.RelativeCycleId == rule.RelativeCycleId &&
                                              v.ClearEventOnDueChange == rule.ClearEventOnDueChange &&
                                              v.ClearDueOnDueChange == rule.ClearDueOnDueChange);
        }

        public static RelatedEventRule InheritRuleFrom(this RelatedEventRule relatedEventRule, RelatedEventRule from)
        {
            relatedEventRule.CopyFrom(from, true);
            return relatedEventRule;
        }

        public static void CopyFrom(this RelatedEventRule relatedEventRule, RelatedEventRule from, bool? isInherited = null)
        {
            if (relatedEventRule == null) throw new ArgumentNullException(nameof(relatedEventRule));
            if (@from == null) throw new ArgumentNullException(nameof(@from));

            if (isInherited.HasValue)
                relatedEventRule.IsInherited = isInherited.Value;

            relatedEventRule.RelatedEventId = from.RelatedEventId;
            relatedEventRule.ClearEvent = from.ClearEvent;
            relatedEventRule.ClearDue = from.ClearDue;
            relatedEventRule.SatisfyEvent = from.SatisfyEvent;
            relatedEventRule.UpdateEvent = from.UpdateEvent;
            relatedEventRule.CreateNextCycle = from.CreateNextCycle;
            relatedEventRule.DateAdjustmentId = from.DateAdjustmentId;
            relatedEventRule.RelativeCycleId = from.RelativeCycleId;
            relatedEventRule.ClearEventOnDueChange = from.ClearEventOnDueChange;
            relatedEventRule.ClearDueOnDueChange = from.ClearDueOnDueChange;
        }

        public static void CopySatisfyingEvent(this RelatedEventRule relatedEventRule, RelatedEventRule from, bool? isInherited = null)
        {
            if (relatedEventRule == null) throw new ArgumentNullException(nameof(relatedEventRule));
            if (@from == null) throw new ArgumentNullException(nameof(@from));

            if (isInherited.HasValue)
                relatedEventRule.IsInherited = isInherited.Value;

            relatedEventRule.RelatedEventId = from.RelatedEventId;
            relatedEventRule.RelativeCycleId = from.RelativeCycleId;
            relatedEventRule.IsSatisfyingEvent = true;
        }

        public static void CopyEventToClear(this RelatedEventRule relatedEventRule, RelatedEventRule from, bool? isInherited = null)
        {
            if (relatedEventRule == null) throw new ArgumentNullException(nameof(relatedEventRule));
            if (@from == null) throw new ArgumentNullException(nameof(@from));

            if (isInherited.HasValue)
                relatedEventRule.IsInherited = isInherited.Value;

            relatedEventRule.RelatedEventId = from.RelatedEventId;
            relatedEventRule.RelativeCycleId = from.RelativeCycleId;
            relatedEventRule.ClearDueOnDueChange = from.ClearDueOnDueChange;
            relatedEventRule.ClearEventOnDueChange = from.ClearEventOnDueChange;
            relatedEventRule.ClearEvent = from.ClearEvent;
            relatedEventRule.ClearDue = from.ClearDue;
        }

        public static void CopyEventToUpdate(this RelatedEventRule relatedEventRule, RelatedEventRule from, bool? isInherited = null)
        {
            if (relatedEventRule == null) throw new ArgumentNullException(nameof(relatedEventRule));
            if (@from == null) throw new ArgumentNullException(nameof(@from));

            if (isInherited.HasValue)
                relatedEventRule.IsInherited = isInherited.Value;

            relatedEventRule.RelatedEventId = from.RelatedEventId;
            relatedEventRule.RelativeCycleId = from.RelativeCycleId;
            relatedEventRule.DateAdjustmentId = from.DateAdjustmentId;
            relatedEventRule.IsUpdateEvent = true;
        }
    }
}