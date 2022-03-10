using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration
{
    public class GraphResourceIdManagerFacts : FactBase
    {
        [Fact]
        public async Task VerifySaveAsync()
        {
            var f = new GraphResourceIdManagerFixture(Db);
            var staffId = Fixture.Integer();
            var createdOn = DateTime.Now;
            var resourceId = Fixture.UniqueName();
            var resourceType = KnownExchangeResourceType.Appointment;
            await f.Subject.SaveAsync(staffId, createdOn, resourceType, resourceId);
            var resource = Db.Set<ExchangeResourceTracker>().FirstOrDefault(x => x.StaffId == staffId && x.SequenceDate == createdOn && x.ResourceId == resourceId && x.ResourceType == (short)resourceType);
            Assert.NotNull(resource);
        }

        [Fact]
        public async Task VerifyGetAsync()
        {
            var f = new GraphResourceIdManagerFixture(Db);
            var staffId = Fixture.Integer();
            var createdOn = DateTime.Now;
            var resourceId = Fixture.UniqueName();
            var resourceType = KnownExchangeResourceType.Appointment;
            new ExchangeResourceTracker(staffId, createdOn, (short)resourceType, resourceId).In(Db);
            var actualResourceId = await f.Subject.GetAsync(staffId, createdOn, resourceType);
            Assert.Equal(resourceId, actualResourceId);
        }

        [Fact]
        public async Task ShouldReturnTrueDeleteAsyncMethod()
        {
            var f = new GraphResourceIdManagerFixture(Db);
            var staffId = Fixture.Integer();
            var createdOn = DateTime.Now;
            var resourceId = Fixture.UniqueName();
            var resourceType = KnownExchangeResourceType.Appointment;
            new ExchangeResourceTracker(staffId, createdOn, (short)resourceType, resourceId).In(Db);
            var result = await f.Subject.DeleteAsync(staffId, createdOn, resourceType, resourceId);
            Assert.True(result);
        }

        [Fact]
        public async Task ShouldReturnFalseDeleteAsyncMethod()
        {
            var f = new GraphResourceIdManagerFixture(Db);
            var result = await f.Subject.DeleteAsync(Fixture.Integer(), DateTime.Now, KnownExchangeResourceType.Email, Fixture.UniqueName());
            Assert.False(result);
        }

        public class GraphResourceIdManagerFixture : IFixture<GraphResourceIdManager>
        {
            public GraphResourceIdManagerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                Subject = new GraphResourceIdManager(DbContext);
            }

            public IDbContext DbContext { get; set; }
            public GraphResourceIdManager Subject { get; set; }
        }
    }
}