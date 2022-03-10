using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.ExternalCaseResolution;
using Inprotech.Integration.Jobs;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Migration;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;
using Job = Inprotech.Integration.Jobs.Job;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Migration
{
    public class BackfillCorrelationIdFacts
    {
        public class NowMethod : FactBase
        {
            [Fact]
            public async Task RunsJobs()
            {
                var f = new BackfillCorrelationIdFixture(Db);
                new Case {Id = 1}.In(Db);
                new JobExecution {Job = new Job {Id = 123456}}.In(Db);

                var r = f.Subject.Now(123456);
                var group = (ActivityGroup) await r;
                var firstActivity = (SingleActivity) group.Items.First();

                Assert.Equal("BackfillCorrelationId.ThisChunk", firstActivity.TypeAndMethod());
            }
        }

        public class ThisChunk : FactBase
        {
            [Fact]
            public async Task CallsResolverWithExactMatchThenUpdates()
            {
                var f = new BackfillCorrelationIdFixture(Db);

                var ids = new[] {1, 2, 3};

                var dResult = new Dictionary<int, int> {{1, 9}, {2, 8}, {3, 7}};
                f.PrivatePairCases.Resolve(Arg.Any<IEnumerable<int>>(), Arg.Any<bool>()).Returns(dResult);
                var r = (SingleActivity) await f.Subject.ThisChunk(ids);

                f.PrivatePairCases.Received(1).Resolve(Arg.Any<IEnumerable<int>>(), true);
                Assert.Equal("BackfillCorrelationId.Update", r.TypeAndMethod());
                Assert.Equal(dResult, r.Arguments[0]);
            }

            [Fact]
            public async Task FuzzyMatchesUnresolvedCaseIds()
            {
                var f = new BackfillCorrelationIdFixture(Db);

                var ids = new[] {1, 2, 3};

                var dResult = new Dictionary<int, int> {{1, 9}, {2, 8}};
                f.PrivatePairCases.Resolve(Arg.Any<IEnumerable<int>>(), Arg.Any<bool>()).Returns(dResult);
                var r = (ActivityGroup) await f.Subject.ThisChunk(ids);
                var nextActivity = (SingleActivity) r.Items.Last();
                var args = ((IEnumerable<int>) nextActivity.Arguments[0]).ToArray();

                f.PrivatePairCases.Received(1).Resolve(Arg.Any<IEnumerable<int>>(), true);
                Assert.Equal("BackfillCorrelationId.FuzzyMatchRemainder", nextActivity.TypeAndMethod());
                Assert.Single(args);
                Assert.Equal(3, args.First());
            }
        }

        public class FuzzyMatchRemainderMethod : FactBase
        {
            [Fact]
            public async Task CallsResolverWithFuzzyMatchThenUpdates()
            {
                var f = new BackfillCorrelationIdFixture(Db);

                var ids = new[] {1, 2, 3};

                var dResult = new Dictionary<int, int> {{1, 9}, {2, 8}, {3, 7}};
                f.PrivatePairCases.Resolve(Arg.Any<IEnumerable<int>>(), Arg.Any<bool>()).Returns(dResult);
                var r = (SingleActivity) await f.Subject.FuzzyMatchRemainder(ids);

                f.PrivatePairCases.Received(1).Resolve(Arg.Any<IEnumerable<int>>(), false);
                Assert.Equal("Update", r.Name);
                Assert.Equal(dResult, r.Arguments[0]);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public async Task UpdatesCaseCorrelationIdWithCaseId()
            {
                var f = new BackfillCorrelationIdFixture(Db);
                var c = new Case {Id = 123}.In(Db);

                var param = new Dictionary<int, int> {{123, 987}, {111, 222}};

                await f.Subject.Update(param);

                Assert.Equal(987, c.CorrelationId);
            }
        }
    }

    public class BackfillCorrelationIdFixture : IFixture<BackfillCorrelationId>
    {
        public BackfillCorrelationIdFixture(InMemoryDbContext db)
        {
            PrivatePairCases = Substitute.For<IPrivatePairCases>();
            Subject = new BackfillCorrelationId(db, PrivatePairCases);
        }

        public IPrivatePairCases PrivatePairCases { get; }
        public BackfillCorrelationId Subject { get; }
    }
}