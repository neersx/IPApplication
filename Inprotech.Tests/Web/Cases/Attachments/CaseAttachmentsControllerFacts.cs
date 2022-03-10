using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Details;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Attachments
{
    public class CaseAttachmentsControllerFacts
    {
        public class GetAttachments : FactBase
        {
            [Fact]
            public async Task DoesNotReturnPagedResultsIfCaseKeyNotProvided()
            {
                var f = new AttachmentsControllerFixture().WithAttachmentsData(-487);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.GetCaseViewAttachments(string.Empty, new CommonQueryParameters()));

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task DoesNotReturnPagedResultsIfCaseKeyNotValid()
            {
                var f = new AttachmentsControllerFixture().WithAttachmentsData(-487);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.GetCaseViewAttachments("1234/abcd", new CommonQueryParameters()));

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task DoesNotReturnPagedResultsIfValid()
            {
                var f = new AttachmentsControllerFixture().WithAttachmentsData(-487);

                var result = await f.Subject.GetCaseViewAttachments("-487", new CommonQueryParameters());

                Assert.Equal(2, result.Data.Count());
                Assert.Equal(2, result.Pagination.Total);
            }

            [Fact]
            public async Task AppliesFilter()
            {
                var f = new AttachmentsControllerFixture().WithAttachmentsData(-487);

                var filters = new List<CommonQueryParameters.FilterValue> {new CommonQueryParameters.FilterValue {Field = "eventNo", Operator = "in", Value = 100.ToString()}};
                var result = await f.Subject.GetCaseViewAttachments("-487", new CommonQueryParameters {Filters = filters});

                Assert.Equal(1, result.Data.Count());
                Assert.Equal(1, result.Pagination.Total);
            }
        }

        public class GetRecentAttachments : FactBase
        {
            [Fact]
            public async Task DoesNotReturnResultsIfCaseKeyNotProvided()
            {
                var f = new AttachmentsControllerFixture().WithAttachmentsData(-487);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.GetCaseViewAttachments(string.Empty, Fixture.Integer(), Fixture.Integer()));

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task DoesNotReturnResultsIfCaseKeyNotValid()
            {
                var f = new AttachmentsControllerFixture().WithAttachmentsData(-487);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.GetCaseViewAttachments("1234/abcd", Fixture.Integer(), Fixture.Integer()));

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsResultsIfValid()
            {
                var f = new AttachmentsControllerFixture().WithAttachmentsData(-487);

                var result = await f.Subject.GetCaseViewAttachments("-487", 100, 1);

                Assert.Equal(1, result.Count());
            }

            [Fact]
            public async Task ReturnsResultsIfValidForCycle()
            {
                var f = new AttachmentsControllerFixture().WithAttachmentsData(-487);

                var result = await f.Subject.GetCaseViewAttachments("-487", 100, 5);

                Assert.Equal(0, result.Count());
            }
        }

        class AttachmentsControllerFixture : IFixture<AttachmentsController>
        {
            public AttachmentsControllerFixture()
            {
                CaseViewAttachmentsProvider = Substitute.For<ICaseViewAttachmentsProvider>();
                SubjectSecurityProvider = Substitute.For<ISubjectSecurityProvider>();
                SubjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments).Returns(true);
                Subject = new AttachmentsController(CaseViewAttachmentsProvider, SubjectSecurityProvider);
            }

            ICaseViewAttachmentsProvider CaseViewAttachmentsProvider { get; }
            ISubjectSecurityProvider SubjectSecurityProvider { get; }

            public AttachmentsController Subject { get; }

            public AttachmentsControllerFixture WithAttachmentsData(int caseId, int eventNo = 99)
            {
                var data = Enumerable.Range(1, 2).Select(_ => new AttachmentItem
                {
                    RawAttachmentName = Fixture.String(_.ToString()),
                    ActivityCategory = Fixture.String(_.ToString()),
                    ActivityDate = Fixture.Monday,
                    ActivityType = Fixture.String(_.ToString()),
                    AttachmentType = Fixture.String(_.ToString()),
                    EventCycle = 1,
                    EventNo = eventNo + _,
                    EventDescription = Fixture.String(_.ToString()),
                    IsPublic = true
                }).ToList();
                CaseViewAttachmentsProvider.GetAttachments(caseId).Returns(data.AsQueryable());
                return this;
            }
        }
    }
}