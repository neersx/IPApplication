using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;
using NSubstitute;
using System.Collections.Generic;
using System.Linq;
using Xunit;

namespace Inprotech.Tests.Web.Cases.EventRules
{
    public class EventUpdateDetailsServiceFacts : FactBase
    {
        EventViewRuleDetails SetupData()
        {
            var eventId = Fixture.Integer();

            return new EventViewRuleDetails
            {
                EventControlDetails = new EventControlDetails
                {
                    CriteriaNo = Fixture.Integer(),
                    EventNo = eventId,
                    UpdateEventImmediately = true,
                    UpdateWhenDue = true,
                    Status = Fixture.String(),
                    CreateAction = Fixture.String(),
                    CloseAction = Fixture.String(),
                    PayFeeCode = 1,
                    ChargeDesc = Fixture.String(),
                    PayFeeCode2 = 2,
                    ChargeDesc2 = Fixture.String(),
                    SetThirdPartyOn = true
                },
                RelatedEventDetails = new List<RelatedEventDetails>
                {
                    new RelatedEventDetails
                    {
                        RelatedEvent = Fixture.Integer(),
                        RelatedEventDesc = Fixture.String(),
                        UpdateEvent = true,
                        RelativeCycle = 3,
                        Adjustment = Fixture.String()
                    },
                    new RelatedEventDetails
                    {
                        RelatedEvent = Fixture.Integer(),
                        RelatedEventDesc = Fixture.String(),
                        UpdateEvent = true,
                        RelativeCycle = 1,
                        Adjustment = Fixture.String()
                    },
                    new RelatedEventDetails
                    {
                        RelatedEvent = Fixture.Integer(),
                        RelatedEventDesc = Fixture.String(),
                        ClearDue = true,
                        RelativeCycle = 3
                    },
                    new RelatedEventDetails
                    {
                        RelatedEvent = Fixture.Integer(),
                        RelatedEventDesc = Fixture.String(),
                        ClearEventOnDueChange = true,
                        RelativeCycle = 3
                    }
                }
            };
        }
        [Fact]
        public void ShouldReturnEventUpdateDetails()
        {
            var data = SetupData();
            var f = new EventUpdateDetailsServiceFixture();
            var desc = Fixture.String();
            f.EventRulesHelper.RelativeCycleToLocalizedString(Arg.Any<int>(), Arg.Any<string[]>()).Returns("next cycle");
            f.EventRulesHelper.RatesCodeToLocalizedString(2, Arg.Any<string[]>()).Returns("Pay Fees");
            f.EventRulesHelper.RatesCodeToLocalizedString(1, Arg.Any<string[]>()).Returns("Raise Charge");
            f.EventRulesHelper.DateTypeToLocalizedString(Arg.Any<int>(), Arg.Any<string[]>()).Returns("event date");
            const string dateTranslate = "caseview.eventRules.eventUpdate.";
            f.StaticTranslator.Translate(dateTranslate + "RaiseChargeLiteral", Arg.Any<IEnumerable<string>>()).Returns("for");
            f.StaticTranslator.Translate(dateTranslate + "ReportToCPA", Arg.Any<IEnumerable<string>>()).Returns("Report to CPA");
            f.StaticTranslator.Translate(dateTranslate + "BooleanLiteral_True", Arg.Any<IEnumerable<string>>()).Returns("on");
            f.StaticTranslator.Translate(dateTranslate + "DateOperationLiteral", Arg.Any<IEnumerable<string>>()).Returns(desc);
            
            var r = f.Subject.GetEventUpdateDetails(data);
            Assert.True(r.UpdateImmediatelyInfo);
            Assert.True(r.UpdateWhenDueInfo);
            Assert.Equal(data.EventControlDetails.Status, r.Status);
            Assert.Equal(data.EventControlDetails.CreateAction, r.CreateAction);
            Assert.Equal(data.EventControlDetails.CloseAction, r.CloseAction);
            Assert.Equal($"Raise Charge for {data.EventControlDetails.ChargeDesc}", r.FeesAndChargesInfo);
            Assert.Equal($"Pay Fees for {data.EventControlDetails.ChargeDesc2}", r.FeesAndChargesInfo2);
            Assert.Equal("Report to CPA on", r.ReportToCpaInfo);

            Assert.Equal(2, r.DatesToUpdate.Count());
            var dateToUpdate = data.RelatedEventDetails.First(_ => _.UpdateEvent.GetValueOrDefault());
            Assert.Equal($"{dateToUpdate.RelatedEventDesc} [next cycle]", r.DatesToUpdate.First().FormattedDescription);
            Assert.Equal(dateToUpdate.Adjustment, r.DatesToUpdate.First().Adjustment);

            Assert.Equal(2, r.DatesToClear.Count());
            var dateToClear = data.RelatedEventDetails.First(_ => _.ClearDue.GetValueOrDefault());
            Assert.Equal($"{dateToClear.RelatedEventDesc} [next cycle] - event date", r.DatesToClear.First());
            var dateToClear2 = data.RelatedEventDetails.First(_ => _.ClearEventOnDueChange.GetValueOrDefault());
            Assert.Equal($"{dateToClear2.RelatedEventDesc} [next cycle] - event date {desc}", r.DatesToClear.Last());
        }

        [Fact]
        public void ShouldReturnNullWhenNoEventUpdateDetails()
        {
            var f = new EventUpdateDetailsServiceFixture();
            var r = f.Subject.GetEventUpdateDetails(new EventViewRuleDetails());
            Assert.Null(r);
        }

        [Fact]
        public void ShouldReturnThirdPartyOff()
        {
            var details = new EventViewRuleDetails
            {
                EventControlDetails = new EventControlDetails
                {
                    CriteriaNo = Fixture.Integer(),
                    EventNo = Fixture.Integer(),
                    SetThirdPartyOff = true
                }
            };
            var f = new EventUpdateDetailsServiceFixture();
            const string dateTranslate = "caseview.eventRules.eventUpdate.";
            var cpaReport = Fixture.String("Report");
            const string off = "off";
            f.StaticTranslator.Translate(dateTranslate + "BooleanLiteral_False", Arg.Any<IEnumerable<string>>()).Returns(off);
            f.StaticTranslator.Translate(dateTranslate + "ReportToCPA", Arg.Any<IEnumerable<string>>()).Returns(cpaReport);
            
            var r = f.Subject.GetEventUpdateDetails(details);
            Assert.Equal($"{cpaReport} {off}", r.ReportToCpaInfo);
        }
    }

    public class EventUpdateDetailsServiceFixture : IFixture<EventUpdateDetailsService>
    {
        public IStaticTranslator StaticTranslator { get; }
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public IEventRulesHelper EventRulesHelper { get; }
        public ISiteControlReader SiteControlReader { get; set; }

        public EventUpdateDetailsServiceFixture()
        {
            StaticTranslator = Substitute.For<IStaticTranslator>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            EventRulesHelper = Substitute.For<IEventRulesHelper>();
            Subject = new EventUpdateDetailsService(PreferredCultureResolver, StaticTranslator, EventRulesHelper);

            PreferredCultureResolver.Resolve().Returns("en");
            PreferredCultureResolver.ResolveAll().Returns(new[] {"en"});
        }
        public EventUpdateDetailsService Subject { get; }
    }
}
