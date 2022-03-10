using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Dates;
using Inprotech.Web.Search.TaskPlanner;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Dates
{
    public class AdHocDatesControllerFacts : FactBase
    {
        [Fact]
        public void ShouldCallGet()
        {
            var fixture = new AdHocDatesControllerFixture();
            var adhocPayload = new AdHocDatePayload
            {
                Message = "Message",
                AdHocDateFor = "George",
                DueDate = Fixture.Date()
            };

            fixture.AdHocDate.Get(Arg.Any<int>()).ReturnsForAnyArgs(adhocPayload);

            var result = fixture.Subject.Get(Fixture.Integer());
            Assert.Equal(adhocPayload, result);
        }

        [Fact]
        public async Task ShouldCreateAdHocDate()
        {
            var fixture = new AdHocDatesControllerFixture();
            var status = new
            {
                Status = ReminderActionStatus.Success
            };

            fixture.AdHocDate.CreateAdhocDate(Arg.Any<AdhocSaveDetails[]>()).ReturnsForAnyArgs(status);
            var result = await fixture.Subject.CreateAdhocDate(new[]
            {
                new AdhocSaveDetails()
            });
            Assert.Equal(status, result);
        }

        [Fact]
        public async Task ShouldCallViewData()
        {
            var fixture = new AdHocDatesControllerFixture();
            var currentUser = new
            {
                Key = Fixture.Integer(),
                Code = "Internal",
                DisplayName = Fixture.String()
            };
            var expectedResult = new
            {
                DefaultImportance = Fixture.Integer(),
                loggedInUser = currentUser
            };
            fixture.AdHocDate.ViewData(null).ReturnsForAnyArgs(expectedResult);
            var result = await fixture.Subject.ViewData();
            var code = result.loggedInUser.Code;
            var expectedCode = expectedResult.loggedInUser.Code;

            Assert.Equal(expectedCode, code);
        }

        [Fact]
        public async Task ShouldCallEventDetails()
        {
            var fixture = new AdHocDatesControllerFixture();
            var expectedResult = new
            {
                Case = new
                {
                    Key = Fixture.Integer(),
                    Code = Fixture.String(),
                    Value = Fixture.String()
                }
            };
            var caseEventId = Fixture.Integer();
            fixture.AdHocDate.CaseEventDetails(caseEventId).ReturnsForAnyArgs(expectedResult);
            var result = await fixture.Subject.CaseEventDetails(caseEventId);

            Assert.Equal(expectedResult.Case.Key, result.Case.Key);
            Assert.Equal(expectedResult.Case.Code, result.Case.Code);
            Assert.Equal(expectedResult.Case.Value, result.Case.Value);
        }

        [Fact]
        public void ShouldCallNameDetails()
        {
            var fixture = new AdHocDatesControllerFixture();
            var expectedResult = new List<Inprotech.Web.Dates.Names>
            {
                new Inprotech.Web.Dates.Names
                {
                    Code = Fixture.String(),
                    DisplayName = Fixture.String(),
                    Key = Fixture.Integer(),
                    Type = Fixture.String()
                },
                new Inprotech.Web.Dates.Names
                {
                    Code = Fixture.String(),
                    DisplayName = Fixture.String(),
                    Key = Fixture.Integer(),
                    Type = Fixture.String()
                }
            };
            var caseId = Fixture.Integer();
            fixture.AdHocDate.NameDetails(caseId).ReturnsForAnyArgs(expectedResult);
            var result = fixture.Subject.NameDetails(caseId).ToArray();

            Assert.Equal(expectedResult.Count, result.Length);
            Assert.Equal(expectedResult[0].Code, result[0].Code);
            Assert.Equal(expectedResult[0].DisplayName, result[0].DisplayName);
            Assert.Equal(expectedResult[0].Key, result[0].Key);
            Assert.Equal(expectedResult[0].Type, result[0].Type);
        }

        [Fact]
        public void ShouldCallRelationshipDetails()
        {
            var fixture = new AdHocDatesControllerFixture();
            var expectedResult = new List<Inprotech.Web.Dates.Names>
            {
                new Inprotech.Web.Dates.Names
                {
                    Code = Fixture.String(),
                    DisplayName = Fixture.String(),
                    Key = Fixture.Integer(),
                    Type = Fixture.String()
                },
                new Inprotech.Web.Dates.Names
                {
                    Code = Fixture.String(),
                    DisplayName = Fixture.String(),
                    Key = Fixture.Integer(),
                    Type = Fixture.String()
                }
            };
            var caseId = Fixture.Integer();
            var nameTypeCode = Fixture.String();
            var relationshipCode = Fixture.String();
            fixture.AdHocDate.RelationshipDetails(caseId, nameTypeCode, relationshipCode).ReturnsForAnyArgs(expectedResult);
            var result = fixture.Subject.RelationshipDetails(caseId, nameTypeCode, relationshipCode).ToArray();

            Assert.Equal(expectedResult.Count, result.Length);
            Assert.Equal(expectedResult[0].Code, result[0].Code);
            Assert.Equal(expectedResult[0].DisplayName, result[0].DisplayName);
            Assert.Equal(expectedResult[0].Key, result[0].Key);
            Assert.Equal(expectedResult[0].Type, result[0].Type);
        }
    }

    public class FinaliseAdHocDatesControllerFacts : FactBase
    {
        [Fact]
        public async Task ShouldCallFinalise()
        {
            var fixture = new AdHocDatesControllerFixture();
            var updateResult = new
            {
                Result = "success"
            };

            fixture.AdHocDate.Finalise(Arg.Any<FinaliseRequestModel>()).ReturnsForAnyArgs(updateResult);

            var result = await fixture.Subject.Finalise(new FinaliseRequestModel());
            Assert.Equal(updateResult, result);
        }

        [Fact]
        public async Task ShouldCallBulkFinalise()
        {
            var fixture = new AdHocDatesControllerFixture();
            var updateResult = new
            {
                Result = "success"
            };

            fixture.AdHocDate.BulkFinalise(Arg.Any<BulkFinaliseRequestModel>()).ReturnsForAnyArgs(updateResult);

            var result = await fixture.Subject.BulkFinalise(new BulkFinaliseRequestModel());
            Assert.Equal(updateResult, result);
        }
    }

    public class MaintainAdHocDatesControllerFacts : FactBase
    {
        [Fact]
        public async Task ShouldMaintainAdHocDate()
        {
            var fixture = new AdHocDatesControllerFixture();
            var status = new
            {
                Status = ReminderActionStatus.Success
            };

            fixture.AdHocDate.MaintainAdhocDate(Fixture.Integer(), Arg.Any<AdhocSaveDetails>()).ReturnsForAnyArgs(status);

            var result = await fixture.Subject.MaintainAdhocDate(Fixture.Integer(), new AdhocSaveDetails());
            Assert.Equal(status, result);
        }
    }

    public class AdHocDatesControllerFixture : IFixture<AdHocDatesController>
    {
        public AdHocDatesControllerFixture()
        {
            AdHocDate = Substitute.For<IAdHocDates>();
            CaseAuthorization = Substitute.For<ICaseAuthorization>();
            Subject = new AdHocDatesController(AdHocDate, CaseAuthorization);
        }

        public IDbContext DbContext { get; set; }
        public IAdHocDates AdHocDate { get; set; }
        public ICaseAuthorization CaseAuthorization { get; set; }
        public AdHocDatesController Subject { get; }
    }
}