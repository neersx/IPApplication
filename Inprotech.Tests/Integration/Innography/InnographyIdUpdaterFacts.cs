using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Innography;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography
{
    public class InnographyIdUpdaterFacts
    {
        public class UpdateMethod : FactBase
        {
            [Fact]
            public async Task ShouldCreateNewActiveLink()
            {
                var db = Db;

                var changeTracker = Substitute.For<IChangeTracker>();
                changeTracker.HasChanged(Arg.Any<CpaGlobalIdentifier>())
                             .Returns(true);

                var innographyId = Fixture.String();

                var @case = new CaseBuilder().Build().In(Db);

                await new InnographyIdUpdater(db, changeTracker).Update(@case.Id, innographyId);

                var id = db.Set<CpaGlobalIdentifier>().Single();

                Assert.Equal(innographyId, id.InnographyId);
                Assert.Equal(@case.Id, id.CaseId);
                Assert.True(id.IsActive);
            }

            [Fact]
            public async Task ShouldMakeExistingLinkActive()
            {
                var db = Db;

                var changeTracker = Substitute.For<IChangeTracker>();
                changeTracker.HasChanged(Arg.Any<CpaGlobalIdentifier>())
                             .Returns(true);

                var @case = new CaseBuilder().Build().In(Db);

                var existing = new CpaGlobalIdentifier
                {
                    CaseId = @case.Id,
                    InnographyId = Fixture.String(),
                    IsActive = false
                }.In(Db);

                await new InnographyIdUpdater(db, changeTracker).Update(@case.Id, existing.InnographyId);

                var now = db.Set<CpaGlobalIdentifier>().Single();

                Assert.True(now.IsActive);
            }
        }

        public class RejectMethod : FactBase
        {
            [Fact]
            public async Task ShouldCreateNewInactiveLink()
            {
                var db = Db;

                var changeTracker = Substitute.For<IChangeTracker>();
                changeTracker.HasChanged(Arg.Any<CpaGlobalIdentifier>())
                             .Returns(true);

                var innographyId = Fixture.String();

                var @case = new CaseBuilder().Build().In(Db);

                await new InnographyIdUpdater(db, changeTracker).Reject(@case.Id, innographyId);

                var id = db.Set<CpaGlobalIdentifier>().Single();

                Assert.Equal(innographyId, id.InnographyId);
                Assert.Equal(@case.Id, id.CaseId);
                Assert.False(id.IsActive);
            }

            [Fact]
            public async Task ShouldMakeExistingLinkInactive()
            {
                var db = Db;

                var changeTracker = Substitute.For<IChangeTracker>();
                changeTracker.HasChanged(Arg.Any<CpaGlobalIdentifier>())
                             .Returns(true);

                var @case = new CaseBuilder().Build().In(Db);

                var existing = new CpaGlobalIdentifier
                {
                    CaseId = @case.Id,
                    InnographyId = Fixture.String(),
                    IsActive = true
                }.In(Db);

                await new InnographyIdUpdater(db, changeTracker).Reject(@case.Id, existing.InnographyId);

                var now = db.Set<CpaGlobalIdentifier>().Single();

                Assert.False(now.IsActive);
            }
        }

        public class ClearMethod : FactBase
        {
            readonly IChangeTracker _changeTracker = Substitute.For<IChangeTracker>();

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void RemovesAllExistingInnographyLinkToCase(bool isActive)
            {
                var db = Db;

                var @case = new CaseBuilder().Build().In(Db);

                new CpaGlobalIdentifier
                {
                    CaseId = @case.Id,
                    InnographyId = Fixture.String(),
                    IsActive = isActive
                }.In(Db);

                new InnographyIdUpdater(db, _changeTracker).Clear(@case.Id);

                Assert.Empty(db.Set<CpaGlobalIdentifier>().Where(_ => _.Id == @case.Id));
            }

            [Fact]
            public void EnsureNoNewInnographyLinkIsEstablished()
            {
                var db = Db;

                var @case = new CaseBuilder().Build().In(Db);

                new InnographyIdUpdater(db, _changeTracker).Clear(@case.Id);

                Assert.Empty(db.Set<CpaGlobalIdentifier>().Where(_ => _.Id == @case.Id));
            }
        }
    }
}