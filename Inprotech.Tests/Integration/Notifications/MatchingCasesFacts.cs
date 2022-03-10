using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.PtoAccess;
using InprotechKaizen.Model.Integration.PtoAccess;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class MatchingCasesFacts
    {
        public class ResolveMethod : FactBase
        {
            [Theory]
            [InlineData("USPTO.PrivatePAIR", DataSourceType.UsptoPrivatePair)]
            [InlineData("USPTO.TSDR", DataSourceType.UsptoTsdr)]
            public void ResolvesEligibleCasesByCorrelationId(string systemCode, DataSourceType dataSource)
            {
                var integrationCase = new Case
                {
                    CorrelationId = 999,
                    Source = dataSource
                }.In(Db);

                var f = new MatchingCasesFixture(Db)
                    .WithEligibleCases(KnownNumberTypes.Application, "12345", 999, systemCode);

                var r = f.Subject.Resolve(systemCode, 999);

                Assert.Equal(999, r[integrationCase.Id]);
            }

            [Theory]
            [InlineData("USPTO.PrivatePAIR", DataSourceType.UsptoPrivatePair)]
            [InlineData("USPTO.TSDR", DataSourceType.UsptoTsdr)]
            public void DoesNotResolvesEligibleCasesForIntegrationCasesWithoutCorrelationId(string systemCode, DataSourceType dataSource)
            {
                var integrationCase = new Case
                {
                    CorrelationId = null,
                    Source = dataSource
                }.In(Db);

                var f = new MatchingCasesFixture(Db)
                    .WithEligibleCases(KnownNumberTypes.Application, "12345", 999);

                var r = f.Subject.Resolve(systemCode, 999);

                Assert.False(r.ContainsKey(integrationCase.Id));
            }
        }

        public class MatchingCasesFixture : IFixture<MatchingCases>
        {
            public MatchingCasesFixture(InMemoryDbContext db)
            {
                FilterDataExtractCases = Substitute.For<IFilterDataExtractCases>();
                Subject = new MatchingCases(db, FilterDataExtractCases);
            }

            public IFilterDataExtractCases FilterDataExtractCases { get; set; }

            public MatchingCases Subject { get; set; }

            public MatchingCasesFixture WithEligibleCases(string numberType, string number, int caseKey, string systemCode = "USPTO.PrivatePAIR")
            {
                return WithEligibleCases(new EligibleCaseItem
                {
                    CaseKey = caseKey,
                    SystemCode = systemCode
                });
            }

            public MatchingCasesFixture WithEligibleCases(params EligibleCaseItem[] results)
            {
                FilterDataExtractCases.For(Arg.Any<string>(), Arg.Any<int[]>())
                                      .ReturnsForAnyArgs((results ?? Enumerable.Empty<EligibleCaseItem>()).AsQueryable());

                return this;
            }
        }
    }
}