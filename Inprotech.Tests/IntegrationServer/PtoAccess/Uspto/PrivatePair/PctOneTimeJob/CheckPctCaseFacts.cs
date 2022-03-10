using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.PctOneTimeJob;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.PctOneTimeJob
{
    public class CheckPctCaseFacts : FactBase
    {
        [Fact]
        public async Task ShouldNotSaveIfNoRelatedCases()
        {
            var f = new CheckPctCaseFixture(Db)
                .WithChange(false);

            await f.Subject.CheckAndUpdateCase(f.CaseNotification.Id);

            f.BufferedStringWriter.DidNotReceive().Write(Arg.Any<string>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldSaveIfChangesMadeToCpaXml()
        {
            var f = new CheckPctCaseFixture(Db)
                .WithChange(true);

            await f.Subject.CheckAndUpdateCase(f.CaseNotification.Id);

            f.BufferedStringWriter.Received(1).Write(Arg.Any<string>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
        }
    }

    internal class CheckPctCaseFixture : IFixture<CheckPctCase>
    {
        public IBufferedStringReader BufferedStringReader = Substitute.For<IBufferedStringReader>();
        public IBufferedStringWriter BufferedStringWriter = Substitute.For<IBufferedStringWriter>();

        public Func<DateTime> SystemClock = Substitute.For<Func<DateTime>>();
        public IUpdateAssociatedRelationCountry UpdateAssociatedRelationCountry = Substitute.For<IUpdateAssociatedRelationCountry>();

        public CheckPctCaseFixture(InMemoryDbContext repository)
        {
            CaseNotification = new CaseNotification {Id = 1, Case = new Case {FileStore = new FileStore {Path = "A"}}};

            repository.Set<CaseNotification>().Add(CaseNotification);
            repository.SaveChanges();

            SystemClock().Returns(Fixture.Today());

            Subject = new CheckPctCase(repository, UpdateAssociatedRelationCountry, BufferedStringReader, BufferedStringWriter, SystemClock);
        }

        public CaseNotification CaseNotification { get; }

        public CheckPctCase Subject { get; }

        public CheckPctCaseFixture WithChange(bool value)
        {
            UpdateAssociatedRelationCountry.TryUpdate(Arg.Any<string>(), out _).Returns(value);

            return this;
        }
    }
}