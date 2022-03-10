using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.PriorArt;
using Inprotech.Web.PriorArt.Maintenance;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using ServiceStack;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.Maintenance
{
    public class MaintainCitationFacts : FactBase
    {
        [Fact]
        public async Task ThrowsWhenPriorArtNotFound()
        {
            var fixture = new MaintainCitationFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await fixture.Subject.DeleteCitation(Fixture.Integer(), Fixture.Integer()));

            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldDeleteCorrectCitationWhenMaintainingSource()
        {
            var fixture = new MaintainCitationFixture(Db);
            var priorArtBuilder = new PriorArtBuilder().In(Db);            
            InprotechKaizen.Model.PriorArt.PriorArt citedPriorArt = priorArtBuilder.Build().In(Db);
            var searchPriorArt = new InprotechKaizen.Model.PriorArt.PriorArt
            {
                Id = Fixture.Integer(),
                IsSourceDocument = true,
                CitedPriorArt = new Collection<InprotechKaizen.Model.PriorArt.PriorArt> {citedPriorArt}
            }.In(Db);
            await fixture.Subject.DeleteCitation(searchPriorArt.Id, citedPriorArt.Id);

            Assert.Equal(searchPriorArt.CitedPriorArt.Count, 0);
            var citedStillExists = Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Where(v => v.Id == citedPriorArt.Id);
            var searchStillExists = Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Where(v => v.Id == searchPriorArt.Id);
            Assert.Equal(citedStillExists.Count(), 1);
            Assert.Equal(searchStillExists.Count(), 1);
        }
    }

    public class MaintainCitationFixture : IFixture<MaintainCitation>
    {
        public MaintainCitationFixture(IDbContext db)
        {
            Subject = new MaintainCitation(db);
        }

        public MaintainCitation Subject { get; }
    }
}
