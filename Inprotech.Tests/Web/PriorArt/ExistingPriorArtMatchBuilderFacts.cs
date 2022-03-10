using System;
using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Integration.Innography;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class ExistingPriorArtMatchBuilderFacts : FactBase
    {
        readonly IPatentScoutUrlFormatter _urlFormatter = Substitute.For<IPatentScoutUrlFormatter>();
        readonly IPreferredCultureResolver _preferredCulture = Substitute.For<IPreferredCultureResolver>();
        [Fact]
        public void ShouldCreateReferenceLink()
        {
            var sourceDocumentId = Fixture.Integer();
            var isCited = Fixture.Boolean();
            var options = new SearchResultOptions
            {
                ReferenceHandling = new SearchResultReferenceHandling
                {
                    IsIpPlatformSession = Fixture.Boolean()
                }
            };

            var art = new InprotechKaizen.Model.PriorArt.PriorArt(Fixture.String(), new Country(Fixture.String(), Fixture.String(), Fixture.String()))
            {
                CorrelationId = Fixture.String()
            };

            var referenceLink = new Uri("https://ps.innography.com");

            _urlFormatter.CreatePatentScoutReferenceLink(art.CorrelationId, options.ReferenceHandling.IsIpPlatformSession)
                         .Returns(referenceLink);

            var subject = new ExistingPriorArtMatchBuilder(_urlFormatter, Db, _preferredCulture);

            var r = (ExistingPriorArtMatch) subject.Build(art, sourceDocumentId, isCited, options);

            Assert.Equal(referenceLink, r.ReferenceLink);
        }

        [Fact]
        public void ShouldPopulateDetailsAccordingly()
        {
            var sourceDocumentId = Fixture.Integer();
            var isCited = Fixture.Boolean();

            var subject = new ExistingPriorArtMatchBuilder(_urlFormatter, Db, _preferredCulture);

            var art = new InprotechKaizen.Model.PriorArt.PriorArt(Fixture.String(), new Country(Fixture.String(), Fixture.String(), Fixture.String()))
            {
                Title = Fixture.String(),
                Abstract = Fixture.String(),
                Citation = Fixture.String(),
                Kind = Fixture.String()
            };

            var r = (ExistingPriorArtMatch) subject.Build(art, sourceDocumentId, isCited, new SearchResultOptions());

            Assert.Equal(art.Id.ToString(), r.Id);
            Assert.Equal(art.OfficialNumber, r.Reference);
            Assert.Equal(art.Title, r.Title);
            Assert.Equal(art.Citation, r.Citation);
            Assert.Equal(art.Abstract, r.Abstract);
            Assert.Equal(art.Kind, r.Kind);
            Assert.Equal(sourceDocumentId, r.SourceDocumentId);
            Assert.Equal(isCited, r.IsCited);
            Assert.Null(r.ReferenceLink);
        }

        [Fact]
        public void ShouldPopulateExtraDetailsAccordingly()
        {
            var sourceDocumentId = Fixture.Integer();
            var isCited = Fixture.Boolean();

            var subject = new ExistingPriorArtMatchBuilder(_urlFormatter, Db, _preferredCulture);

            var art = new InprotechKaizen.Model.PriorArt.PriorArt(Fixture.String(), new Country(Fixture.String(), Fixture.String(), Fixture.String()))
            {
                Title = Fixture.String(),
                Abstract = Fixture.String(),
                Citation = Fixture.String(),
                Kind = Fixture.String(),
                ApplicationFiledDate = Fixture.Monday,
                GrantedDate = Fixture.Tuesday,
                PublishedDate = Fixture.Monday,
                Name = Fixture.String(),
                Translation = Fixture.Integer(),
                Description = Fixture.String(),
                Comments = Fixture.String(),
                PriorityDate = Fixture.Monday
            };

            var r = (ExistingPriorArtMatch) subject.Build(art, sourceDocumentId, isCited, new SearchResultOptions());

            Assert.Equal(art.ApplicationFiledDate, r.ApplicationDate);
            Assert.Equal(art.GrantedDate, r.GrantedDate);
            Assert.Equal(art.PublishedDate, r.PublishedDate);
            Assert.Equal(art.Name, r.Name);
            Assert.Equal(art.Translation, r.Translation);
            Assert.Equal(art.Description, r.Description);
            Assert.Equal(art.Comments, r.Comments);
            Assert.Null(r.RefDocumentParts);
            Assert.Equal(art.PriorityDate, r.PriorityDate);
            Assert.Null(r.PtoCitedDate);
        }

        [Fact]
        public void ShouldPopulateDetailsAccordinglyIfCaseKeyPassed()
        {
            var sourceDocumentId = Fixture.Integer();
            var isCited = Fixture.Boolean();
            var existingCountry = new Country("au", "au").In(Db);
            
            var @case = new CaseBuilder().Build().In(Db);
            @case.Country = existingCountry;
            var caseSearchResult = new CaseSearchResult
            {
                CaseId = @case.Id,
                StatusId = Fixture.Integer()
            }.In(Db);
            
            var priorArtStatus = new TableCodeBuilder
            {
                TableCode = caseSearchResult.StatusId,
                Description = Fixture.String()
            }.Build().In(Db);

            var caseSearchResultSet = new Collection<CaseSearchResult> {caseSearchResult};

            var subject = new ExistingPriorArtMatchBuilder(_urlFormatter, Db, _preferredCulture);

            var art = new InprotechKaizen.Model.PriorArt.PriorArt(Fixture.String(), existingCountry)
            {
                Title = Fixture.String(),
                Abstract = Fixture.String(),
                Citation = Fixture.String(),
                Kind = Fixture.String(),
                CaseSearchResult = caseSearchResultSet
            };

            var r = (ExistingPriorArtMatch) subject.Build(art, sourceDocumentId, isCited, new SearchResultOptions(), caseSearchResult, @case.Id);

            Assert.Equal(r.CountryName, existingCountry.Name);
            Assert.Equal(r.Origin, "Inprotech");
            Assert.Equal(r.PriorArtStatus, priorArtStatus.Name);
        }

        [Fact]
        public void ShouldGetTranslationList()
        {
            new TableCodeBuilder().For(TableTypes.PriorArtTranslation).Build().In(Db);
            new TableCodeBuilder().For(TableTypes.PriorArtTranslation).Build().In(Db);
            
            var subject = new ExistingPriorArtMatchBuilder(_urlFormatter, Db, _preferredCulture);
            var r = subject.GetPriorArtTranslations();

            Assert.Equal(2, r.Count());
        }
    }
}