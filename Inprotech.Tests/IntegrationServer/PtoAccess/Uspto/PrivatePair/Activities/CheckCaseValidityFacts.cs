using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class CheckCaseValidityFacts : FactBase
    {
        [Fact]
        public async Task IsValidCallsCorrelationIdUpdator()
        {
            var f = new CheckCaseValidityFixture(Db);
            await f.Subject.IsValid("app1");

            f.CorrelationIdUpdator.Received(1).UpdateIfRequired(Arg.Any<Case>());
        }

        [Fact]
        public async Task IsValidCallsCorrelationIdUpdatorWithCase()
        {
            var @case = new Case {ApplicationNumber = "app1234", Source = DataSourceType.UsptoPrivatePair};
            var f = new CheckCaseValidityFixture(Db).WithCase(@case);

            await f.Subject.IsValid("app1234");

            f.CorrelationIdUpdator.Received(1).UpdateIfRequired(@case);
        }

        [Fact]
        public async Task IsValidCallsCorrelationIdUpdatorWithNullValue()
        {
            var @case = new Case {ApplicationNumber = "app1234", Source = DataSourceType.Epo};
            var f = new CheckCaseValidityFixture(Db).WithCase(@case);

            await f.Subject.IsValid("app1234");

            f.CorrelationIdUpdator.Received(1).UpdateIfRequired(null);
        }
    }

    public class CheckCaseValidityFixture : IFixture<ICheckCaseValidity>
    {
        readonly InMemoryDbContext _db;

        public CheckCaseValidityFixture(InMemoryDbContext db)
        {
            _db = db;
            CorrelationIdUpdator = Substitute.For<ICorrelationIdUpdator>();

            Subject = new CheckCaseValidity(db, CorrelationIdUpdator);
        }

        public ICorrelationIdUpdator CorrelationIdUpdator { get; }
        public ICheckCaseValidity Subject { get; }

        public CheckCaseValidityFixture WithCase(Case @case)
        {
            _db.Set<Case>().Add(@case);

            return this;
        }
    }
}