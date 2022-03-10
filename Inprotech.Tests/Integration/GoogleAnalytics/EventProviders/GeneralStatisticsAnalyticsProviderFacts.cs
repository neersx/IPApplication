using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using Xunit;
using Action = System.Action;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class GeneralStatisticsAnalyticsProviderFacts : FactBase
    {
        [Fact]
        public async Task ReturnNewCases()
        {
            var f = Subject();
            var c = SetupNewCase();

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(1 + 1, r.Length);
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == ResolveEventName(c.Type, c.PropertyType)).Value));
        }

        [Fact]
        public async Task ReturnsWellKnownPropertyTypeCases()
        {
            var f = Subject();

            void Loop(Action e, int count = 2)
            {
                for (int i = 0; i < count; i++)
                {
                    e();
                }
            }

            var c = SetupNewCase();
            Loop(() => SetupNewCase(KnownPropertyTypes.Design, KnownCaseTypes.CampaignOrMarketingEvent));
            Loop(() => SetupNewCase(KnownPropertyTypes.TradeMark, KnownCaseTypes.Opportunity), 3);
            SetupNewCase(KnownPropertyTypes.Patent, "Y");

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(1, ToInt(r.Single(_ => _.Name == ResolveEventName(c.Type, c.PropertyType)).Value));
            Assert.Equal(2, ToInt(r.Single(_ => _.Name == WithSuffix("Marketing Activities", "Designs")).Value));
            Assert.Equal(3, ToInt(r.Single(_ => _.Name == WithSuffix("CRM", "Trademark")).Value));
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == WithSuffix("Internal", "Patent")).Value));
        }

        [Fact]
        public async Task ReturnDocGenerated()
        {
            var f = Subject();
            SetupCaseActivityHistory(Fixture.Short());
            SetupCaseActivityHistory(Fixture.Short(), Fixture.PastDate().AddDays(-1));
            SetupCaseActivityHistory(null);

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(1, r.Length);
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.StatisticsDocGenerated).Value));
        }

        GeneralStatisticsAnalyticsProvider Subject() => new GeneralStatisticsAnalyticsProvider(Db);

        string WithSuffix(string part1, string part2) => $"{AnalyticsEventCategories.StatisticsNewCasesPrefix}{part1}.Cases.{part2}";
        string ResolveEventName(CaseType ct, PropertyType pt) => WithSuffix($"{ct.Name}[{ct.Code}]", $"{pt.Name}[{pt.Code}]");

        int ToInt(string text) => Convert.ToInt32(text);

        Case SetupNewCase(string propertyTypeId = null, string caseType = null, int? caseId = null)
        {
            var @case = new CaseBuilder()
            {
                PropertyType = new PropertyType(propertyTypeId ?? Fixture.String(), Fixture.String()).In(Db),
                CaseType = new CaseType(caseType ?? Fixture.String(), Fixture.String()).In(Db)
            }.BuildWithId(caseId ?? Fixture.Integer()).In(Db);
            new CaseEventBuilder()
            {
                EventNo = (int)KnownEvents.DateOfEntry,
                Cycle = 1,
                EventDate = Fixture.Today()
            }.BuildForCase(@case).In(Db);
            return @case;
        }

        void SetupCaseActivityHistory(short? letterNo, DateTime? occurred = null)
        {
            new CaseActivityHistory()
            {
                WhenOccurred = occurred ?? Fixture.Today(),
                LetterNo = letterNo
            }.In(Db);
        }
    }
}