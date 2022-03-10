using System.Collections.Generic;
using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public class GoodsServicesConverterFacts
    {
        readonly CaseDetails _caseDetails = new CaseDetails("Trademark", "US");
        readonly GoodsServicesConverter _subject = new GoodsServicesConverter();
        TsdrSourceFixture _fixture;

        [Fact]
        public void ResolvesNiceClassifications()
        {
            var source = new GoodsServicesBuilder
                {
                    KindCodeClassNumberPair = new Dictionary<string, string>
                    {
                        {"Nice", "030"},
                        {"Primary", "040"},
                        {"National", "1"}
                    }
                }.Build()
                 .InGoodsServicesBag()
                 .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal("Nice", _caseDetails.GoodsServicesDetails.Single().ClassificationTypeCode);
            Assert.Equal("030",
                         _caseDetails.GoodsServicesDetails.Single()
                                     .ClassDescriptionDetails.ClassDescriptions.Single()
                                     .ClassNumber);
        }

        [Fact]
        public void ReturnsAsManyGoodsServices()
        {
            var all = new GoodsServicesBagBuilder();
            all.GoodsServices.AddRange(new[]
            {
                new GoodsServicesBuilder
                {
                    ClassNumber = "030",
                    GoodsServicesDescription = "a"
                }.Build(),
                new GoodsServicesBuilder
                {
                    ClassNumber = "031",
                    GoodsServicesDescription = "b"
                }.Build(),
                new GoodsServicesBuilder
                {
                    ClassNumber = "032",
                    GoodsServicesDescription = "c"
                }.Build()
            });

            _fixture = new TsdrSourceFixture().With(all.Build().AsTsdrSource());
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal(3, _caseDetails.GoodsServicesDetails.Count);
            Assert.Equal(new[] {"030", "031", "032"},
                         _caseDetails.GoodsServicesDetails.SelectMany(
                                                                      _ => _.ClassDescriptionDetails.ClassDescriptions.Select(c => c.ClassNumber)
                                                                     ));
            Assert.Equal(new[] {"a", "b", "c"},
                         _caseDetails.GoodsServicesDetails.SelectMany(
                                                                      _ =>
                                                                          _.ClassDescriptionDetails.ClassDescriptions.Select(
                                                                                                                             c => c.GoodsServicesDescription.Single().Value)
                                                                     ));
        }

        [Fact]
        public void ReturnsGoodsServicesDetails()
        {
            var source = new GoodsServicesBuilder
                {
                    ClassNumber = "030",
                    GoodsServicesDescription = "Rental and on-line rental services of video recordings",
                    FirstUsedDate = "20080909",
                    FirstUsedInCommerceDate = "20090808"
                }.Build()
                 .InGoodsServicesBag()
                 .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var classDescription =
                _caseDetails.GoodsServicesDetails.First().ClassDescriptionDetails.ClassDescriptions.Single();

            Assert.Equal("030", classDescription.ClassNumber);
            Assert.Equal("Rental and on-line rental services of video recordings",
                         classDescription.GoodsServicesDescription.Single().Value);
            Assert.Equal("20080909", classDescription.FirstUsedDate);
            Assert.Equal("20090808", classDescription.FirstUsedDateInCommerce);
        }

        [Fact]
        public void ReturnsNationalGoodsServicesAlternatively()
        {
            var source = new GoodsServicesBuilder
                         {
                             KindCodeClassNumberPair = new Dictionary<string, string>
                             {
                                 {"Nice", "030"},
                                 {"Primary", "040"},
                                 {"National", "1"}
                             }
                         }
                         .WithAlternateGoodsServicesDescription("Canned Bean", "National")
                         .Build()
                         .InGoodsServicesBag()
                         .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var classDescription =
                _caseDetails.GoodsServicesDetails.First().ClassDescriptionDetails.ClassDescriptions.Single();

            Assert.Equal("030", classDescription.ClassNumber);
            Assert.Equal("Canned Bean",
                         classDescription.GoodsServicesDescription.Single().Value);
        }
    }
}