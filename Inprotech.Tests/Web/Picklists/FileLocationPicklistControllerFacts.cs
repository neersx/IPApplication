using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class FileLocationPicklistControllerFacts : FactBase
    {
        public FileLocationPicklistControllerFacts()
        {
            _controller = new FileLocationPicklistController(Db, Substitute.For<IPreferredCultureResolver>());
        }

        readonly FileLocationPicklistController _controller;

        [Fact]
        public void ShouldOrderByExactMatchAndFollowedByDescriptionCode()
        {
            var builder = new TableCodeBuilder
            {
                TableType = (short) TableTypes.FileLocation,
                Description = "a2"
            };

            var tb1 = builder.Build().In(Db);
            builder.Description = "a1";
            builder.Build().In(Db);
            builder.Description = "a";
            builder.Build().In(Db);

            var office = new InprotechKaizen.Model.Cases.Office {Id = Fixture.Integer(), Name = Fixture.String("Office")}.In(Db);
            new FileLocationOffice(tb1, office).In(Db);

            var r = _controller.Search(null, "a").Data.ToArray();

            Assert.Equal(3, r.Length);
            Assert.Equal("a", r[0].Value);
            Assert.Equal("a1", r[1].Value);
            Assert.Equal("a2", r[2].Value);
            Assert.Equal(office.Name, r[2].Office);
        }

        [Fact]
        public void ShouldSearchByOffice()
        {
            var builder = new TableCodeBuilder
            {
                TableType = (short) TableTypes.FileLocation,
                Description = "a2"
            };

            var tb1 = builder.Build().In(Db);

            var office = new InprotechKaizen.Model.Cases.Office {Id = Fixture.Integer(), Name = Fixture.String("Office")}.In(Db);
            new FileLocationOffice(tb1, office).In(Db);

            var r = _controller.Search(null, office.Name).Data.ToArray();

            Assert.Single(r);
            Assert.Equal(office.Name, r[0].Office);
        }

        [Fact]
        public void ShouldSearchForDescription()
        {
            var id = new TableCode(1, (short) TableTypes.FileLocation, "ab").In(Db).Id;
            var r = _controller.Search(null, "b").Data;

            Assert.Equal(id, r.Single().Key);
        }
    }
}