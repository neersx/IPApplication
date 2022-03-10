using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Components.Names;
using Xunit;

namespace Inprotech.Tests.Model.Components.Names
{
    public class DisplayFormattedNameFacts : FactBase
    {
        [Theory]
        [InlineData("Smith, John", "Smith", "John", "Prof.", null)]
        [InlineData("Smith John Prof.", "Smith", "John", "Prof.", NameStyles.FamilyNameThenFirstNames)]
        [InlineData("Prof. John Smith", "Smith", "John", "Prof.", NameStyles.FirstNameThenFamilyName)]
        [InlineData("Smith, John", "Smith", "John", "Prof.", NameStyles.Default)]
        public async Task ShouldUseExistingNameFormatting(string expectedFormattedName, string lastName, string firstName, string title, NameStyles? nameStyle)
        {
            var name = new NameBuilder(Db){LastName = lastName, FirstName = firstName }.Build();
            name.Title = title;
            name.NameStyle = (int?)nameStyle;
            name.In(Db);

            var f = new DisplayFormattedNameFixture(Db);
            var result = await f.Subject.For(new[] {name.Id});

            Assert.Equal(expectedFormattedName, result[name.Id].Name);
        }

        public class DisplayFormattedNameFixture : IFixture<DisplayFormattedName>
        {
            public DisplayFormattedNameFixture(InMemoryDbContext db)
            {
                Subject = new DisplayFormattedName(db);
            }

            public DisplayFormattedName Subject { get; }
        }
    }
}