using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class ComponentsControllerFacts : FactBase
    {
        public class ComponentsControllerFixture : IFixture<ComponentsController>
        {
            public ComponentsControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.GetSortedPage(
                                                 Arg.Any<IQueryable<ComponentResult>>(),
                                                 Arg.Any<CommonQueryParameters>()
                                                ).Returns(_ => (IEnumerable<ComponentResult>) _[0]);
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new ComponentsController(DbContext, CommonQueryService, PreferredCultureResolver);
            }

            public InMemoryDbContext DbContext { get; }
            public ICommonQueryService CommonQueryService { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public ComponentsController Subject { get; }

            public void AddComponent(string componentName)
            {
                new Component
                {
                    ComponentName = componentName
                }.In(DbContext);
            }
        }

        [Fact]
        public void ReturnsAllComponentsWhenNoFilter()
        {
            var f = new ComponentsControllerFixture(Db);

            f.AddComponent("Component1");
            f.AddComponent("Component2");
            f.AddComponent("AlsoReturn");
            var result = f.Subject.Search(null, null);

            var results = ((IEnumerable<dynamic>) result.Data).ToArray();

            Assert.Equal(3, results.Count());
        }

        [Fact]
        public void ReturnsFilteredComponents()
        {
            var f = new ComponentsControllerFixture(Db);

            f.AddComponent("Component1");
            f.AddComponent("Component2");
            f.AddComponent("Component3");
            f.AddComponent("DoNotReturn");

            var result = f.Subject.Search("Component", null);
            result.Data.ToList();

            var results = ((IEnumerable<ComponentResult>) result.Data).ToArray();

            Assert.Equal(3, results.Length);
            Assert.Equal("Component1", results[0].ComponentName);
            Assert.Equal("Component2", results[1].ComponentName);
            Assert.Equal("Component3", results[2].ComponentName);
        }
    }
}