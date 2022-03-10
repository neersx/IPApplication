using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Lists;
using Xunit;

namespace Inprotech.Tests.Web.Lists
{
    public class NameVariantControllerFacts : FactBase
    {
        [Fact]
        public void ShouldGetNameVariantByNameId()
        {
            var name = new NameVariantBuilder(Db) {Id = 1, NameVariantDesc = "a"}.Build();
            name.FirstNameVariant = "Bob";

            name.In(Db);

            var controller = new NameVariantController(Db);

            var results = (IEnumerable<dynamic>) controller.Get(name.Name.Id);

            Assert.Equal(name.Id, results.First().Key);
            Assert.Equal("a, Bob", results.First().Description);
        }
    }
}