using System.Globalization;
using System.Linq;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Configuration.SiteControl;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class SiteControlTextSearchFacts
    {
        public class SearchTextMethod : FactBase
        {
            public IQueryable<SiteControl> Query()
            {
                return Db.Set<SiteControl>().AsQueryable();
            }

            [Fact]
            public void DoNotReturnSiteControlWhenNoMatches()
            {
                SiteControlBuilderWrapper.Generate(Db, "S1", Fixture.String());
                SiteControlBuilderWrapper.Generate(Db, "S2", Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: "not a valid site control");

                var results = Query().SearchText(options, string.Empty).ToArray();

                Assert.Empty(results);
            }

            [Fact]
            public void ReturnSiteControlSearchingByBooleanValue()
            {
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", true);
                SiteControlBuilderWrapper.Generate(Db, Fixture.String(), false);
                SiteControlBuilderWrapper.Generate(Db, Fixture.String(), Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByValue: true, text: true.ToString());

                var results = Query().SearchText(options, string.Empty).ToArray();

                Assert.NotNull(results.SingleOrDefault(_ => _.ControlId == s1.ControlId));
                Assert.Single(results);
            }

            [Fact]
            public void ReturnSiteControlSearchingByDecimalValue()
            {
                const decimal decimalValue = (decimal) 1.45778548;
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", decimalValue);
                SiteControlBuilderWrapper.Generate(Db, Fixture.String(), Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByValue: true, text: decimalValue.ToString(CultureInfo.InvariantCulture));

                var results = Query().SearchText(options, string.Empty).ToArray();

                Assert.NotNull(results.SingleOrDefault(_ => _.ControlId == s1.ControlId));
            }

            [Fact]
            public void ReturnSiteControlSearchingByDescription()
            {
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", Fixture.String());
                s1.SiteControlDescription = "Description VQ100";
                SiteControlBuilderWrapper.Generate(Db, "S2", Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(true, text: "VQ");

                var results = Query().SearchText(options, string.Empty).ToArray();

                Assert.NotNull(results.SingleOrDefault(_ => _.ControlId == s1.ControlId));
            }

            [Fact]
            public void ReturnSiteControlSearchingByIntegerValue()
            {
                var integerValue = Fixture.Integer();
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", integerValue);
                SiteControlBuilderWrapper.Generate(Db, Fixture.String(), Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByValue: true, text: integerValue.ToString(CultureInfo.InvariantCulture));

                var results = Query().SearchText(options, string.Empty).ToArray();

                Assert.NotNull(results.SingleOrDefault(_ => _.ControlId == s1.ControlId));
            }

            [Fact]
            public void ReturnSiteControlSearchingByName()
            {
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", Fixture.String());
                SiteControlBuilderWrapper.Generate(Db, "S2", Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: "S1");

                var results = Query().SearchText(options, string.Empty).ToArray();

                Assert.NotNull(results.SingleOrDefault(_ => _.ControlId == s1.ControlId));
            }

            [Fact]
            public void ReturnSiteControlSearchingByNameIgnoringSymbols()
            {
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S.1", Fixture.String());
                SiteControlBuilderWrapper.Generate(Db, "S,2", Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByName: true, text: "S~!@#$%^&*()1");

                var results = Query().SearchText(options, string.Empty).ToArray();

                Assert.NotNull(results.SingleOrDefault(_ => _.ControlId == s1.ControlId));
            }

            [Fact]
            public void ReturnSiteControlSearchingStringValue()
            {
                var s1 = SiteControlBuilderWrapper.Generate(Db, "S1", "stringValue-VQ100");
                SiteControlBuilderWrapper.Generate(Db, Fixture.String(), Fixture.String());
                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByValue: true, text: "stringValue-VQ100");

                var results = Query().SearchText(options, string.Empty).ToArray();
                Assert.NotNull(results.SingleOrDefault(_ => _.ControlId == s1.ControlId));
            }

            [Fact]
            public void ReturnsSiteControlSearchingByValueDecimalAndInteger()
            {
                SiteControlBuilderWrapper.Generate(Db, "S1", 10);
                SiteControlBuilderWrapper.Generate(Db, "S2", (decimal) 10);

                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByValue: true, text: 10.ToString());

                var results = Query().SearchText(options, string.Empty).ToArray();

                Assert.Equal(2, results.Length);
            }

            [Fact]
            public void ReturnsSiteControlSearchingByValueStringAndBoolean()
            {
                SiteControlBuilderWrapper.Generate(Db, "S1", true);
                SiteControlBuilderWrapper.Generate(Db, "S2", "True");

                var options = SiteControlBuilderWrapper.CreateSearchOptions(isByValue: true, text: true.ToString());

                var results = Query().SearchText(options, string.Empty).ToArray();

                Assert.Equal(2, results.Length);
            }
        }
    }
}