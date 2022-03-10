using System;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.PriorArt;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class PriorArtAttachmentsControllerFacts : FactBase
    {
        public class GetPriorArtViewAttachments : FactBase
        {
            [Fact]
            public async Task ThrowsNotFoundIfSourceProvidedDoNotExist()
            {
                var subject = new PriorArtAttachmentsControllerFixture(Db).Subject;

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await subject.GetPriorArtViewAttachments(string.Empty));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsUnauthorisedIfNotAllowedToViewAttachments()
            {
                var subject = new PriorArtAttachmentsControllerFixture(Db).Subject;

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await subject.GetPriorArtViewAttachments("3", CommonQueryParameters.Default));
                Assert.Equal(HttpStatusCode.Unauthorized, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsPriorArtAttachments()
            {
                var priorArt = new PriorArtBuilder().Build().In(Db);
                var activityType = new TableCodeBuilder
                {
                    Description = "prior art activity type",
                    TableType = (short?) TableTypes.ContactActivityType

                }.Build().In(Db);
                var activityCategory = new TableCodeBuilder
                {
                    Description = "prior art activity category",
                    TableType = (short?) TableTypes.ContactActivityCategory

                }.Build().In(Db);
                var attachmentType = new TableCodeBuilder
                {
                    Description = "prior art attachment type",
                    TableType = (short?) TableTypes.AttachmentType

                }.Build().In(Db);
                var language = new TableCodeBuilder
                {
                    Description = "prior art language",
                    TableType = (short?) TableTypes.Language

                }.Build().In(Db);
                var activity1 = new Activity {Id = 111, PriorartId = priorArt.Id, ActivityType = activityType, ActivityCategory = activityCategory, ActivityDate = DateTime.Today}.In(Db);
                new ActivityAttachment(activity1.Id, 0){AttachmentName = "prior art file name", AttachmentType = attachmentType, Language = language}.In(Db);
                var subject = new PriorArtAttachmentsControllerFixture(Db);
                subject.SubjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments).Returns(true);
                var r = await subject.Subject.GetPriorArtViewAttachments(priorArt.Id.ToString(), new CommonQueryParameters());

                Assert.Equal(1, r.Pagination.Total);
            }
        }
        
        public class PriorArtAttachmentsControllerFixture : IFixture<PriorArtAttachmentsController>
        {
            public PriorArtAttachmentsControllerFixture(InMemoryDbContext db)
            {
                SubjectSecurityProvider = Substitute.For<ISubjectSecurityProvider>();
                Subject = new PriorArtAttachmentsController(db, SubjectSecurityProvider);
            }
            public ISubjectSecurityProvider SubjectSecurityProvider { get; set; }
            public PriorArtAttachmentsController Subject { get; }
        }
    }
}
