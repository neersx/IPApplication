using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Reporting
{
    public class StandardReportFormattingDataResolverFacts : FactBase
    {
        readonly ILegacyFormattingDataProvider _formattingDataProvider = Substitute.For<ILegacyFormattingDataProvider>();
        readonly IDisplayFormattedName _displayFormattedName = Substitute.For<IDisplayFormattedName>();
        readonly int _homeNameNo = Fixture.Integer();
        
        StandardReportFormattingDataResolver CreateSubject()
        {
            var siteControlReader = Substitute.For<ISiteControlReader>();
            siteControlReader.Read<int>(SiteControls.HomeNameNo).Returns(_homeNameNo);
            return new StandardReportFormattingDataResolver(Db, _formattingDataProvider, siteControlReader, _displayFormattedName);
        }

        [Fact]
        public async Task ShouldFindFormatsInFormattingData()
        {
            var user = new User(Fixture.String(), false)
            {
                NameId = Fixture.Integer()
            }.In(Db);

            var culture = Fixture.String();

            _formattingDataProvider.Provide(culture)
                                   .Returns(new LegacyStandardReportFormattingData()
                                   {
                                       DateFormat = "dd-MMM-yyyy",
                                       TimeFormat = "h:mm tt",
                                       CurrencyFormat = "$#,##0.00;($#,##0.00)",
                                       LocalCurrencyFormat = "#,##0.00;(#,##0.00)",
                                       LocalCurrencyFormatWithSymbol = "$#,##0.00;($#,##0.00)",
                                       CurrencyDecimalPlaces = new()
                                       {
                                           {"AUD", 0 },
                                           {"USD", 2 }
                                       }
                                   });

            _displayFormattedName.For(Arg.Any<int[]>())
                                 .Returns(x =>
                                 {
                                     return ((int[])x[0]).ToDictionary(k => k, v => new NameFormatted());
                                 });

            var r = await CreateSubject().Resolve(user.Id, culture);

            var formats = r.Descendants("Format").ToArray();

            Assert.Equal("dd-MMM-yyyy", (string) formats.Single(f => (string) f.Attribute("name") == "DateFormat"));
            Assert.Equal("h:mm tt", (string) formats.Single(f => (string) f.Attribute("name") == "TimeFormat"));
            Assert.Equal("$#,##0.00;($#,##0.00)", (string) formats.Single(f => (string) f.Attribute("name") == "CurrencyFormat"));
            Assert.Equal("#,##0.00;(#,##0.00)", (string) formats.Single(f => (string) f.Attribute("name") == "LocalCurrencyFormat"));
            Assert.Equal("$#,##0.00;($#,##0.00)", (string) formats.Single(f => (string) f.Attribute("name") == "LocalCurrencyFormatWithSymbol"));

            var expectedCurrencyDecimalPlaces = new XElement("Format",
                                                             new XAttribute("name", "CurrencyDecimalInfo"),
                                                             new XElement("CurrencyDecimalPlaces",
                                                                          new XAttribute("DecimalPlaces", 0),
                                                                          new XAttribute("CurrencyCode", "AUD")),
                                                             new XElement("CurrencyDecimalPlaces",
                                                                          new XAttribute("DecimalPlaces", 2),
                                                                          new XAttribute("CurrencyCode", "USD"))
                                                            ).ToString();
            
            Assert.Equal(expectedCurrencyDecimalPlaces, formats.Single(f => (string) f.Attribute("name") == "CurrencyDecimalInfo").ToString());
        }

        [Fact]
        public async Task ShouldFindDataInFormattingData()
        {
            var user = new User(Fixture.String(), false)
            {
                NameId = Fixture.Integer()
            }.In(Db);

            var culture = Fixture.String();

            _formattingDataProvider.Provide(culture)
                                   .Returns(new LegacyStandardReportFormattingData());

            _displayFormattedName.For(Arg.Any<int[]>())
                                 .Returns(new Dictionary<int, NameFormatted>
                                 {
                                     {
                                         _homeNameNo, new NameFormatted
                                         {
                                             Name = "Maxim Yarrow and Colman"
                                         }
                                     },
                                     {
                                         user.NameId, new NameFormatted
                                         {
                                             Name = "George, Grey"
                                         }
                                     }
                                 });

            var r = await CreateSubject().Resolve(user.Id, culture);

            var data = r.Descendants("Data").ToArray();

            Assert.Equal("George, Grey", (string) data.Single(f => (string) f.Attribute("name") == "UserName"));
            Assert.Equal("Maxim Yarrow and Colman", (string) data.Single(f => (string) f.Attribute("name") == "FirmName"));
        }
    }
}
