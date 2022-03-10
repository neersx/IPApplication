using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Names.Details;
using Xunit;

namespace Inprotech.Tests.Web.Names.Details
{
    public class NameInternalDetailsControllerFacts : FactBase
    {
        [Theory]
        [InlineData(-7, -3, "dawg")]
        [InlineData(-1, 0, "poooy")]
        public void ReturnInternalNameDetails(int entered, int changed, string soundex)
        {
            var dateEntered = DateTime.Now.AddDays(entered);
            var dateChanged = DateTime.Now.AddDays(changed);

            var name = new NameBuilder(Db)
            {
                Soundex = soundex,
                DateChanged = dateChanged,
                DateEntered = dateEntered
            }.Build().In(Db);

            var f = new NameInternalDetailsControllerFixture(Db);

            var result = f.Subject.GetNameInternalDetails(name.Id);
            Assert.Equal(dateEntered, result.DateEntered);
            Assert.Equal(dateChanged, result.DateChanged);
            Assert.Equal(soundex, result.SoundexCode);
        }
    }

    class NameInternalDetailsControllerFixture : IFixture<NameInternalDetailsController>
    {
        public NameInternalDetailsControllerFixture(InMemoryDbContext db)
        {
            Subject = new NameInternalDetailsController(db);
        }
        public NameInternalDetailsController Subject { get; }
    }
}
