using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Documents;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class DueDateCalcBuilder : IBuilder<DueDateCalc>
    {
        public short? Sequence { get; set; }

        public decimal? Inherited { get; set; }

        public ValidEvent ValidEvent { get; set; }

        public string JurisdictionId { get; set; }

        public int? FromEventId { get; set; }

        public DueDateCalc Build()
        {
            return new DueDateCalc(ValidEvent, Sequence ?? Fixture.Short())
            {
                Inherited = Inherited ?? Fixture.Decimal(),
                Cycle = Fixture.Short(),
                JurisdictionId = JurisdictionId ?? Fixture.String(),
                FromEventId = FromEventId,
                RelativeCycle = Fixture.Short(),
                Operator = Fixture.String(),
                DeadlinePeriod = Fixture.Short(),
                PeriodType = Fixture.String()
            };
        }
    }

    public class DueDateCalcSaveModelBuilder : DueDateCalcBuilder
    {
        public new DueDateCalcSaveModel Build()
        {
            ValidEvent = ValidEvent ?? new ValidEventBuilder().Build();
            var returnModel = new DueDateCalcSaveModel();
            returnModel.CopyFrom(base.Build());
            return returnModel;
        }

        public DueDateCalcSaveModelBuilder For(ValidEvent validEvent)
        {
            ValidEvent = validEvent;
            return this;
        }
    }

    public static class DueDateCalcBuilderExt
    {
        public static DueDateCalcBuilder For(this DueDateCalcBuilder builder, ValidEvent validEvent)
        {
            builder.ValidEvent = validEvent;
            return builder;
        }
    }

    public class DateComparisonSaveModelBuilder : DueDateCalcBuilder
    {
        public new DateComparisonSaveModel Build()
        {
            ValidEvent = ValidEvent ?? new ValidEventBuilder().Build();
            var returnModel = new DateComparisonSaveModel();
            returnModel.CopyFrom(base.Build());
            returnModel.FromEventId = Fixture.Integer();
            returnModel.RelativeCycle = Fixture.Short();
            returnModel.Comparison = Fixture.String();
            return returnModel;
        }

        public DateComparisonSaveModelBuilder For(ValidEvent validEvent)
        {
            ValidEvent = validEvent;
            return this;
        }
    }

    public class RelatedEventRuleBuilder : IBuilder<RelatedEventRule>
    {
        public short? Sequence { get; set; }

        public decimal? Inherited { get; set; }

        public ValidEvent ValidEvent { get; set; }

        public bool IsSatisfyingEvent { get; set; }
        public int? RelatedEventId { get; set; }

        public bool IsClearEvent { get; set; }
        public bool IsUpdateEvent { get; set; }

        public RelatedEventRule Build()
        {
            ValidEvent = ValidEvent ?? new ValidEventBuilder().Build();
            return new RelatedEventRule(ValidEvent, Sequence ?? Fixture.Short())
            {
                Inherited = Inherited ?? Fixture.Decimal(),
                SatisfyEvent = IsSatisfyingEvent ? 1 : 0,
                RelatedEventId = RelatedEventId ?? Fixture.Integer(),
                IsClearEvent = IsClearEvent,
                IsUpdateEvent = IsUpdateEvent
            };
        }
    }

    public static class RelatedEventRuleBuilderExt
    {
        public static RelatedEventRuleBuilder AsSatisfyingEvent(this RelatedEventRuleBuilder builder)
        {
            builder.IsSatisfyingEvent = true;
            return builder;
        }

        public static RelatedEventRuleBuilder AsEventToClear(this RelatedEventRuleBuilder builder)
        {
            builder.IsClearEvent = true;
            return builder;
        }

        public static RelatedEventRuleBuilder AsEventToUpdate(this RelatedEventRuleBuilder builder)
        {
            builder.IsUpdateEvent = true;
            return builder;
        }

        public static RelatedEventRuleBuilder For(this RelatedEventRuleBuilder builder, ValidEvent validEvent)
        {
            builder.ValidEvent = validEvent;
            return builder;
        }
    }

    public class RelatedEventSaveModelBuilder : RelatedEventRuleBuilder
    {
        public new RelatedEventRuleSaveModel Build()
        {
            ValidEvent = ValidEvent ?? new ValidEventBuilder().Build();
            var returnModel = new RelatedEventRuleSaveModel();
            returnModel.CopyFrom(base.Build(), Inherited == 1);
            returnModel.Sequence = Sequence ?? Fixture.Short();
            returnModel.RelatedEventId = Fixture.Integer();
            returnModel.RelativeCycle = Fixture.Short();
            return returnModel;
        }

        public RelatedEventSaveModelBuilder AsEventToClear()
        {
            IsClearEvent = true;
            return this;
        }

        public RelatedEventSaveModelBuilder AsEventToUpdate()
        {
            IsUpdateEvent = true;
            return this;
        }

        public RelatedEventSaveModelBuilder For(ValidEvent validEvent)
        {
            ValidEvent = validEvent;
            return this;
        }
    }

    public class SatisfyingEventSaveModelBuilder : RelatedEventRuleBuilder
    {
        public new RelatedEventRuleSaveModel Build()
        {
            ValidEvent = ValidEvent ?? new ValidEventBuilder().Build();
            var returnModel = new RelatedEventRuleSaveModel();
            returnModel.CopyFrom(base.Build());
            returnModel.Sequence = Sequence ?? Fixture.Short();
            returnModel.SatisfyEvent = 1;
            returnModel.RelatedEventId = Fixture.Integer();
            returnModel.RelativeCycle = Fixture.Short();
            returnModel.Inherited = Inherited ?? Fixture.Decimal();
            return returnModel;
        }

        public SatisfyingEventSaveModelBuilder For(ValidEvent validEvent)
        {
            ValidEvent = validEvent;
            return this;
        }
    }

    public class DatesLogicBuilder : IBuilder<DatesLogic>
    {
        public short? Sequence { get; set; }

        public decimal? Inherited { get; set; }

        public ValidEvent ValidEvent { get; set; }

        public DatesLogic Build()
        {
            var caseRelationship = new CaseRelationBuilder().Build();
            var compareEvent = new EventBuilder().Build();
            return new DatesLogic(ValidEvent, Sequence ?? Fixture.Integer())
            {
                Inherited = Inherited ?? Fixture.Decimal(),
                DateTypeId = Fixture.Short(2),
                Operator = Fixture.String(),
                CompareEvent = new EventBuilder().Build(),
                CompareEventId = compareEvent.Id,
                CompareDateTypeId = Fixture.Short(3),
                CaseRelationshipId = caseRelationship.Relationship,
                CaseRelationship = caseRelationship,
                RelativeCycle = Fixture.Short(),
                MustExist = Fixture.Boolean() ? 1 : 0,
                DisplayErrorFlag = Fixture.Boolean() ? 1 : 0,
                ErrorMessage = Fixture.String()
            };
        }
    }

    public static class DatesLogicBuilderExt
    {
        public static DatesLogicBuilder For(this DatesLogicBuilder builder, ValidEvent validEvent)
        {
            builder.ValidEvent = validEvent;
            return builder;
        }
    }

    public class DatesLogicSaveModelBuilder : DatesLogicBuilder
    {
        public new DatesLogicSaveModel Build()
        {
            ValidEvent = ValidEvent ?? new ValidEventBuilder().Build();
            var returnModel = new DatesLogicSaveModel();
            returnModel.CopyFrom(base.Build(), Inherited == 1);
            returnModel.Sequence = Sequence ?? Fixture.Short();
            returnModel.RelativeCycle = Fixture.Short();
            return returnModel;
        }

        public DatesLogicSaveModelBuilder For(ValidEvent validEvent)
        {
            ValidEvent = validEvent;
            return this;
        }
    }

    public class ReminderRuleBuilder : IBuilder<ReminderRule>
    {
        public short? Sequence { get; set; }

        public decimal? Inherited { get; set; }

        public string Message1 { get; set; }

        public short? LetterNo { get; set; }

        public int? UpdateEvent { get; set; }

        public Document Letter { get; set; }

        public ValidEvent ValidEvent { get; set; }

        public ReminderRule Build()
        {
            if (ValidEvent == null)
            {
                ValidEvent = new ValidEventBuilder().Build();
            }

            return new ReminderRule(ValidEvent, Sequence ?? Fixture.Short())
            {
                Inherited = Inherited ?? Fixture.Decimal(),
                LetterNo = LetterNo ?? Letter?.Id,
                Message1 = LetterNo == null && Letter == null ? Message1 ?? Fixture.String() : null,
                LeadTime = Fixture.Short(),
                PeriodType = Fixture.String(),
                Frequency = Fixture.Short(),
                FreqPeriodType = Fixture.String(),
                StopTime = Fixture.Short(),
                StopTimePeriodType = Fixture.String(),
                MaxLetters = Fixture.Short(),
                UpdateEvent = UpdateEvent ?? Fixture.Integer(),
                Letter = Letter
            };
        }
    }

    public static class ReminderRuleExt
    {
        public static ReminderRuleBuilder For(this ReminderRuleBuilder builder, ValidEvent validEvent)
        {
            builder.ValidEvent = validEvent;
            return builder;
        }

        public static ReminderRuleBuilder AsReminderRule(this ReminderRuleBuilder builder)
        {
            builder.Message1 = Fixture.String();
            builder.LetterNo = null;
            builder.Letter = null;
            return builder;
        }

        public static ReminderRuleBuilder AsDocumentRule(this ReminderRuleBuilder builder, Document document = null)
        {
            builder.Letter = document ?? new DocumentBuilder().Build();
            return builder;
        }
    }

    public class ReminderRuleSaveModelBuilder : ReminderRuleBuilder
    {
        public new ReminderRuleSaveModel Build()
        {
            ValidEvent = ValidEvent ?? new ValidEventBuilder().Build();
            var returnModel = new ReminderRuleSaveModel();
            returnModel.CopyFrom(base.Build());
            return returnModel;
        }

        public ReminderRuleSaveModelBuilder AsReminderRule()
        {
            Message1 = Fixture.String();
            LetterNo = null;
            Letter = null;
            return this;
        }

        public ReminderRuleSaveModelBuilder AsDocumentRule(Document document = null)
        {
            Letter = document ?? new DocumentBuilder().Build();
            return this;
        }

        public ReminderRuleSaveModelBuilder For(ValidEvent validEvent)
        {
            ValidEvent = validEvent;
            return this;
        }
    }

    public class NameTypeMapBuilder : IBuilder<NameTypeMap>
    {
        public short? Sequence { get; set; }

        public bool? Inherited { get; set; }

        public ValidEvent ValidEvent { get; set; }

        public NameType ApplicableNameType { get; set; }
        public NameType SubstituteNameType { get; set; }
        public bool? MustExist { get; set; }

        public NameTypeMap Build()
        {
            var appNameType = ApplicableNameType ?? new NameTypeBuilder().Build();
            var subNameType = SubstituteNameType ?? new NameTypeBuilder().Build();
            var validEvent = ValidEvent ?? new ValidEventBuilder().Build();

            return new NameTypeMap(validEvent, null, null, Sequence ?? Fixture.Short())
            {
                Sequence = Sequence ?? Fixture.Short(),
                MustExist = MustExist ?? Fixture.Boolean(),
                ApplicableNameType = appNameType,
                ApplicableNameTypeKey = appNameType?.NameTypeCode,
                SubstituteNameTypeKey = subNameType?.NameTypeCode,
                SubstituteNameType = subNameType,
                Inherited = Inherited ?? Fixture.Boolean()
            };
        }
    }

    public static class NameTypeMapBuilderExt
    {
        public static NameTypeMapBuilder For(this NameTypeMapBuilder builder, ValidEvent validEvent)
        {
            builder.ValidEvent = validEvent;
            return builder;
        }
    }

    public class RequiredEventRuleBuilder : IBuilder<RequiredEventRule>
    {
        public Event RequiredEvent { get; set; }

        public bool? Inherited { get; set; }

        public ValidEvent ValidEvent { get; set; }

        public RequiredEventRule Build()
        {
            if (RequiredEvent == null)
            {
                RequiredEvent = new EventBuilder().Build();
            }

            return new RequiredEventRule(ValidEvent, RequiredEvent)
            {
                Inherited = Inherited ?? Fixture.Boolean(),
                RequiredEvent = RequiredEvent
            };
        }
    }

    public static class RequiredEventRuleBuilderExt
    {
        public static RequiredEventRuleBuilder For(this RequiredEventRuleBuilder builder, ValidEvent validEvent)
        {
            builder.ValidEvent = validEvent;
            return builder;
        }
    }
}