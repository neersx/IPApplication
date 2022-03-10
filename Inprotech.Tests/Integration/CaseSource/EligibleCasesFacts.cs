using System.Linq;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model.Components.Integration.PtoAccess;
using InprotechKaizen.Model.Integration.PtoAccess;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.CaseSource
{
    public class EligibleCasesFacts
    {
        [Fact]
        public void CallsAppropriateMethods()
        {
            var caseIds = new[] {1};
            var eligibleCaseItems = new[] {new EligibleCaseItem {CaseKey = 1}};
            var f = new EligibleCasesFixture()
                    .WithReturnCaseResolver(caseIds)
                    .WithFilteredCases(eligibleCaseItems)
                    .WithRestrictor(DataSourceType.IpOneData, eligibleCaseItems);

            var session = new DataDownload {DataSourceType = DataSourceType.IpOneData};
            var result = f.Subject.Resolve(session, 1, 1);

            f.ProvideCaseResolvers.Received(1).Get(session);
            f.ResolveCasesForDownload.Received(1).GetCaseIds(session, 1, 1);

            f.FilterDataExtractCases.Received(1).For("IPOneData", caseIds);

            f.SourceRestrictor.Received(1).Restrict(Arg.Is<IQueryable<EligibleCaseItem>>(x => x.ToArray().First().CaseKey.Equals(eligibleCaseItems.First().CaseKey)));

            Assert.Equal(result.First().CaseKey, eligibleCaseItems.First().CaseKey);
        }

        [Fact]
        public void ChunkRequestsIfLargeNumberOfCases()
        {
            var caseIds = Enumerable.Range(0, 28000).ToArray();

            var f = new EligibleCasesFixture()
                .WithReturnCaseResolver(caseIds);

            var session = new DataDownload {DataSourceType = DataSourceType.IpOneData};
            f.Subject.Resolve(session, 1, 1);

            f.FilterDataExtractCases.Received(3).For("IPOneData", Arg.Any<int[]>());
        }
    }

    public class EligibleCasesFixture : IFixture<EligibleCases>
    {
        public EligibleCasesFixture()
        {
            SourceRestrictor = Substitute.For<ISourceRestrictor>();

            ResolveCasesForDownload = Substitute.For<IResolveCasesForDownload>();

            ProvideCaseResolvers = Substitute.For<IProvideCaseResolvers>();

            FilterDataExtractCases = Substitute.For<IFilterDataExtractCases>();

            RestrictionRegistrations = Substitute.For<IIndex<DataSourceType, ISourceRestrictor>>();

            var logger = Substitute.For<IBackgroundProcessLogger<EligibleCases>>();

            Subject = new EligibleCases(ProvideCaseResolvers, FilterDataExtractCases, RestrictionRegistrations, logger);
        }

        public ISourceRestrictor SourceRestrictor { get; }

        public IResolveCasesForDownload ResolveCasesForDownload { get; }

        public IProvideCaseResolvers ProvideCaseResolvers { get; }

        public IFilterDataExtractCases FilterDataExtractCases { get; }

        public IIndex<DataSourceType, ISourceRestrictor> RestrictionRegistrations { get; }

        public EligibleCases Subject { get; }

        public EligibleCasesFixture WithReturnCaseResolver(int[] caseIds)
        {
            ProvideCaseResolvers.Get(Arg.Any<DataDownload>()).Returns(ResolveCasesForDownload);

            ResolveCasesForDownload.GetCaseIds(Arg.Any<DataDownload>(), Arg.Any<int>(), Arg.Any<int>())
                                   .Returns(caseIds);

            return this;
        }

        public EligibleCasesFixture WithRestrictor(DataSourceType dataSourceType, EligibleCaseItem[] eligibleCaseItems)
        {
            SourceRestrictor.Restrict(Arg.Any<IQueryable<EligibleCaseItem>>(), DownloadType.All)
                            .Returns(eligibleCaseItems.AsQueryable());

            RestrictionRegistrations.TryGetValue(dataSourceType, out _)
                                    .Returns(x =>
                                    {
                                        x[1] = SourceRestrictor;
                                        return true;
                                    });

            return this;
        }

        public EligibleCasesFixture WithFilteredCases(EligibleCaseItem[] eligibleCaseItems)
        {
            var queryable = eligibleCaseItems.AsQueryable();

            FilterDataExtractCases.For(Arg.Any<string>(), Arg.Any<int[]>())
                                  .Returns(queryable);

            return this;
        }
    }
}