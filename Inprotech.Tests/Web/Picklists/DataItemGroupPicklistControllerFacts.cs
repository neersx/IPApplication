using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class DataItemGroupPicklistControllerFacts : FactBase
    {
        public class DataItemGroupMethod : FactBase
        {
            [Fact]
            public void ReturnsDataItemGroupContainingMatchingDescription()
            {
                var f = new DataItemGroupPicklistControllerFixture(Db);
                var dataItemGroup = f.Setup();

                var r = f.Subject.DataItemGroups(null, "Case");
                var dig = r.Data.OfType<DataItemGroup>().ToArray();

                Assert.Equal(2, dig.Length);
                Assert.Equal(dataItemGroup.group1.Name, dig.First().Value);
                Assert.Equal(dataItemGroup.group2.Name, dig.Last().Value);
            }

            [Fact]
            public void ReturnsDataItemGroupSortedByName()
            {
                var f = new DataItemGroupPicklistControllerFixture(Db);
                var dataItemGroup = f.Setup();

                var r = f.Subject.DataItemGroups();
                var dig = r.Data.OfType<DataItemGroup>().ToArray();

                Assert.Equal(5, dig.Length);
                Assert.Equal(dataItemGroup.group3.Name, dig.Last().Value);
                Assert.Equal(dataItemGroup.group1.Name, dig.First().Value);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new DataItemGroupPicklistControllerFixture(Db).Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("DataItemGroups").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("DataItemGroup", picklistAttribute.Name);
            }
        }
    }

    public class DataItemGroupPicklistControllerFixture : IFixture<DataItemGroupPicklistController>
    {
        readonly InMemoryDbContext _db;

        public DataItemGroupPicklistControllerFixture(InMemoryDbContext db)
        {
            _db = db;
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            DataItemGroupPicklistMaintenance = Substitute.For<IDataItemGroupPicklistMaintenance>();
            Subject = new DataItemGroupPicklistController(_db, PreferredCultureResolver, DataItemGroupPicklistMaintenance);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public IDataItemGroupPicklistMaintenance DataItemGroupPicklistMaintenance { get; set; }
        public DataItemGroupPicklistController Subject { get; }

        public dynamic Setup()
        {
            var group1 = new Group(0, "Case").In(_db);

            var group2 = new Group(40, "Case Validation").In(_db);

            var group3 = new Group(41, "Name Validation").In(_db);

            var group4 = new Group(38, "Fees").In(_db);

            var group5 = new Group(38, "Email").In(_db);

            return new {group1, group2, group3, group4, group5};
        }
    }
}