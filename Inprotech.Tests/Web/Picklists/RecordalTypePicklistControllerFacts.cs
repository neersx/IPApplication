using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using NSubstitute;
using System.Linq;
using System.Reflection;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class RecordalTypePicklistControllerFixture : IFixture<RecordalTypePicklistController>
    {
        public RecordalTypePicklistControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new RecordalTypePicklistController(db, PreferredCultureResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public RecordalTypePicklistController Subject { get; }
    }
    public class RecordalTypePicklistControllerFacts : FactBase
    {
        [Fact]
        public void ShouldBeDecoratedWithPicklistPayloadAttribute()
        {
            var subjectType = new RecordalTypePicklistControllerFixture(Db).Subject.GetType();
            var picklistAttribute = subjectType.GetMethod("RecordalTypes")?.GetCustomAttribute<PicklistPayloadAttribute>();

            Assert.NotNull(picklistAttribute);
            Assert.Equal("RecordalTypePicklistItem", picklistAttribute.Name);
        }

        [Fact]
        public void ReturnsPagedResults()
        {
            var f = new RecordalTypePicklistControllerFixture(Db);

            var r1 = new RecordalType {Id = 1, RecordalTypeName = "Change of Owner"}.In(Db);
            new RecordalType {Id = 2, RecordalTypeName = "Change of Address"}.In(Db);
            
            var qParams = new CommonQueryParameters {SortBy = "Value", SortDir = "asc", Skip = 1, Take = 1};
            var r = f.Subject.RecordalTypes(qParams);
            var types = r.Data.OfType<RecordalTypePicklistItem>().ToArray();

            Assert.Equal(2, r.Pagination.Total);
            Assert.Single(types);
            Assert.Equal(r1.Id, types.Single().Key);
        }

        [Fact]
        public void ReturnsRequestAndRecordEvent()
        {
            var f = new RecordalTypePicklistControllerFixture(Db);

            var event1 = new EventBuilder().Build().In(Db);
            var r1 = new RecordalType {Id = 1, RecordalTypeName = "Change of Owner", RecordActionId = "AS", RecordEventId = event1.Id, RecordEvent = event1}.In(Db);
            var r2 = new RecordalType {Id = 2, RecordalTypeName = "Change of Address", RequestActionId = "AS", RequestEventId = event1.Id, RequestEvent = event1}.In(Db);
            
            var r = f.Subject.RecordalTypes(new CommonQueryParameters());
            var types = r.Data.OfType<RecordalTypePicklistItem>().ToArray();

            Assert.Equal(r1.Id, types[1].Key);
            Assert.Equal(r1.RecordalTypeName, types[1].Value);
            Assert.Equal(r1.RecordEvent.Description, types[1].RecordEvent);
            Assert.Null(types[1].RequestEvent);
            Assert.Equal(r2.Id, types[0].Key);
            Assert.Equal(r2.RecordalTypeName, types[0].Value);
            Assert.Equal(r2.RequestEvent.Description, types[0].RequestEvent);
            Assert.Null(types[0].RecordEvent);
        }

        [Fact]
        public void ReturnsRecordalTypesContainingSearchStringOrderedByKey()
        {
            var f = new RecordalTypePicklistControllerFixture(Db);

            var r1 = new RecordalType {Id = 1, RecordalTypeName = "Change of Owner"}.In(Db);
            var r2 = new RecordalType {Id = 2, RecordalTypeName = "Change of Owner1"}.In(Db);
            new RecordalType {Id = 3, RecordalTypeName = "Change of Address"}.In(Db);

            var j = f.Subject.RecordalTypes(null, "Ow").Data.OfType<RecordalTypePicklistItem>().ToArray();

            Assert.Equal(r1.Id, j[0].Key);
            Assert.Contains(j, x => x.Key == r2.Id);
        }
    }
}
