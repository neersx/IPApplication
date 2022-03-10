using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;
using Characteristic = InprotechKaizen.Model.StandingInstructions.Characteristic;

namespace Inprotech.Tests.Web.Picklists
{
    public class CharcteristicsPicklistControllerFacts : FactBase
    {
        public class CharacteristicsMethod : FactBase
        {
            [Theory]
            [InlineData("application")]
            [InlineData("file")]
            public void SearchForExactAndContainsMatchOnDescription(string searchText)
            {
                var f = new CharacteristicsPicklistControllerFixture(Db);

                new Characteristic {Id = Fixture.Short(), Description = "Send reminders about examination deadline"}.In(Db);
                new Characteristic {Id = Fixture.Short(), Description = "File application just before deadline"}.In(Db);
                new Characteristic {Id = Fixture.Short(), Description = "File application after further instruction"}.In(Db);

                var r = f.Subject.Characteristics(null, searchText);

                var j = r.Data.OfType<Inprotech.Web.Picklists.Characteristic>().ToArray();

                Assert.Equal(2, j.Length);
            }

            [Fact]
            public void ReturnsCharcteristicsContainingSearchStringOrderedByDescription()
            {
                var f = new CharacteristicsPicklistControllerFixture(Db);

                var record1 = new Characteristic {Id = Fixture.Short(), Description = "abc"}.In(Db);
                new Characteristic {Id = Fixture.Short(), Description = "daf"}.In(Db);
                var record3 = new Characteristic {Id = Fixture.Short(), Description = "xaz"}.In(Db);

                var r = f.Subject.Characteristics(null, "a");

                var j = r.Data.OfType<Inprotech.Web.Picklists.Characteristic>().ToArray();

                Assert.Equal(3, j.Length);
                Assert.Equal(record1.Description, j.First().Description);
                Assert.Equal(record3.Description, j.Last().Description);
            }

            [Fact]
            public void ReturnsCharcteristicsForSpecificInstructionType()
            {
                var f = new CharacteristicsPicklistControllerFixture(Db);

                var record1 = new Characteristic {Id = Fixture.Short(), Description = "abc", InstructionTypeCode = "A"}.In(Db);
                var record2 = new Characteristic {Id = Fixture.Short(), Description = "daf", InstructionTypeCode = "A"}.In(Db);
                new Characteristic {Id = Fixture.Short(), Description = "xaz", InstructionTypeCode = "B"}.In(Db);

                var r = f.Subject.Characteristics(null, "a", "A");

                var j = r.Data.OfType<Inprotech.Web.Picklists.Characteristic>().ToArray();

                Assert.Equal(2, j.Length);
                Assert.Equal(record1.Description, j.First().Description);
                Assert.Equal(record2.Description, j.Last().Description);
            }
        }
    }

    public class CharacteristicsPicklistControllerFixture : IFixture<CharacteristicsPicklistController>
    {
        public CharacteristicsPicklistControllerFixture(InMemoryDbContext db)
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            Subject = new CharacteristicsPicklistController(db, preferredCultureResolver);
        }

        public CharacteristicsPicklistController Subject { get; }
    }
}