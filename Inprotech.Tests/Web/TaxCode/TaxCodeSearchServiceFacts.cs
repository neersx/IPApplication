using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.TaxCode;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.TaxCode
{
    public class TaxCodeSearchServiceFacts : FactBase
    {
        public class ViewTaxCode : FactBase
        {
            readonly IPreferredCultureResolver _preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            [Fact]
            public void ShouldReturnAllTaxCodes()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new TaxRate("1") { Description = "desc" }.In(Db);
                new TaxRate("2") { Description = Fixture.String() }.In(Db);
                new TaxRate("3") { Description = Fixture.String() }.In(Db);
                new TaxRate("4") { Description = Fixture.String() }.In(Db);
                new TaxRate("5") { Description = Fixture.String() }.In(Db);
                var f = new TaxCodeSearchServiceFixture(Db);
                var result = f.Subject.DoSearch(null, cultureResolver.ToString());
                var taxCodes = result.ToArray();

                Assert.NotNull(result);
                Assert.Equal(taxCodes.Length, 5);
            }

            [Fact]
            public void ShouldReturnTaxCodeDetailMatchingWithTaxCode()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new TaxRate("T1") { Description = "desc" }.In(Db);
                new TaxRate("T2") { Description = Fixture.String() }.In(Db);
                new TaxRate("T3") { Description = Fixture.String() }.In(Db);

                var searchOptions = new SearchOptions
                {
                    Text = "T1"
                };
                var f = new TaxCodeSearchServiceFixture(Db);

                var result = f.Subject.DoSearch(searchOptions, cultureResolver.ToString());
                Assert.NotNull(result);
                var taxCodes = result.ToArray();
                Assert.Equal(taxCodes.Count(), 1);
                Assert.Equal(taxCodes[0].Description, "desc");
                Assert.Equal(taxCodes[0].TaxCode, "T1");
            }

            [Fact]
            public void ShouldReturnDefaultSortedTaxCodes()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new TaxRate("T1") { Description = "desc" }.In(Db);
                new TaxRate("T2") { Description = Fixture.String() }.In(Db);
                new TaxRate("T3") { Description = Fixture.String() }.In(Db);
                new TaxRate("T4") { Description = Fixture.String() }.In(Db);

                var f = new TaxCodeSearchServiceFixture(Db);

                var result = f.Subject.DoSearch(null, cultureResolver.ToString());
                Assert.NotNull(result);
                var taxCodes = result.ToArray();
                Assert.Equal(taxCodes.Count(), 4);
                Assert.Equal(taxCodes.First().TaxCode, "T1");
                Assert.Equal(taxCodes.Last().TaxCode, "T4");
            }
        }
    }

    public class TaxCodeSearchServiceFixture : IFixture<ITaxCodeSearchService>
    {
        public TaxCodeSearchServiceFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            Subject = new TaxCodeSearchService(db);
            SecurityContext.User.Returns(new User(Fixture.String(), false));
        }

        public ISecurityContext SecurityContext { get; set; }
        public ITaxCodeSearchService Subject { get; }
    }
}