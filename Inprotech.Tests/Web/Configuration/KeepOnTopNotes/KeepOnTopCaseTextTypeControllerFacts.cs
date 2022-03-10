using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.KeepOnTopNotes;
using InprotechKaizen.Model;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.KeepOnTopNotes
{
    public class KeepOnTopCaseTextTypeControllerFacts
    {
        public class GetKotTextTypes : FactBase
        {
            [Fact]
            public void ReturnsAllKotCaseTextTypes()
            {
                var f = new KeepOnTopCaseTextTypeControllerFixture();
                var data = new List<KotTextType>
                {
                    new KotTextType
                    {
                        Id = Fixture.Integer(),
                        Modules = Fixture.String(),
                        CaseTypes = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        StatusSummary = Fixture.String(),
                        TextType = Fixture.String("Dbc")
                    },
                    new KotTextType
                    {
                        Id = Fixture.Integer(),
                        Modules = Fixture.String(),
                        CaseTypes = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        StatusSummary = Fixture.String(),
                        TextType = Fixture.String("Bcd")
                    }
                };
                f.KeepOnTopTextTypes.GetKotTextTypes(KnownKotTypes.Case).Returns(data);
                var r = f.Subject.GetKeepOnTopCaseTextTypes(null, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>)r).ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(data[1].TextType, results[0].TextType);
            }
            [Fact]
            public void ReturnsFilteredKotCaseTextTypes()
            {
                var f = new KeepOnTopCaseTextTypeControllerFixture();
                var data = new List<KotTextType>
                {
                    new KotTextType
                    {
                        Id = Fixture.Integer(),
                        Modules = "mod",
                        CaseTypes = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        StatusSummary = Fixture.String(),
                        TextType = Fixture.String("Bcd")
                    }
                };
                f.KeepOnTopTextTypes.GetKotTextTypes(KnownKotTypes.Case).Returns(data);
                KeepOnTopSearchOptions options = new KeepOnTopSearchOptions()
                {
                    Modules = "mod, abc".Split(','),
                    Type = KnownKotTypes.Case
                };
                f.KeepOnTopTextTypes.GetKotTextTypes(KnownKotTypes.Case, options).Returns(data);
                var r = f.Subject.GetKeepOnTopCaseTextTypes(options, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>)r).ToArray();

                Assert.Equal(1, results.Length);
            }
        }

        public class GetKotTextTypeDetails : FactBase
        {
            [Fact]
            public async Task ShouldGetCaseKotTextType()
            {
                var f = new KeepOnTopCaseTextTypeControllerFixture();

                await f.Subject.GetKeepOnTopTextTypeCaseDetails(1);
                await f.KeepOnTopTextTypes.Received(1).GetKotTextTypeDetails(1, KnownKotTypes.Case);
            }
        }

        public class SaveKotTextType : FactBase
        {
            [Fact]
            public async Task ShouldSaveCaseKotTextType()
            {
                var f = new KeepOnTopCaseTextTypeControllerFixture();
                var kotData = new KotTextTypeData();
                var response = new KotSaveResponse { Id = Fixture.Integer() };
                f.KeepOnTopTextTypes.SaveKotTextType(kotData, KnownKotTypes.Case).Returns(response);
                var result = await f.Subject.SaveKeepOnTopCaseTextType(kotData);
                Assert.Equal(result.Id, response.Id);
                await f.KeepOnTopTextTypes.Received(1).SaveKotTextType(kotData, KnownKotTypes.Case);
            }
        }

        public class DeleteKotTextType : FactBase
        {
            [Fact]
            public async Task ShouldDeleteKotTextType()
            {
                var f = new KeepOnTopCaseTextTypeControllerFixture();
                f.KeepOnTopTextTypes.DeleteKotTextType(Arg.Any<int>()).Returns(new DeleteResponse { Result = "success" });
                var response = await f.Subject.DeleteKeepOnTopTextType(Fixture.Integer());
                Assert.Equal("success", response.Result);
                await f.KeepOnTopTextTypes.Received(1).DeleteKotTextType(Arg.Any<int>());
            }

            [Fact]
            public async Task ShouldReturnError()
            {
                var f = new KeepOnTopCaseTextTypeControllerFixture();
                f.KeepOnTopTextTypes.DeleteKotTextType(Arg.Any<int>()).Throws(new HttpResponseException(HttpStatusCode.NotFound));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () =>
                {
                    await f.Subject.DeleteKeepOnTopTextType(Fixture.Integer());
                });
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }

        public class GetKeepOnTopNameTextTypesPermissions : FactBase
        {
            [Fact]
            public void ShouldCheckKotPermission()
            {
                var f = new KeepOnTopCaseTextTypeControllerFixture();

                var r = f.Subject.GetKeepOnTopTextTypesPermissions();
                Assert.False(r.MaintainKeepOnTopNotesCaseType);
                Assert.False(r.MaintainKeepOnTopNotesNameType);
            }
        }
    }

    public class KeepOnTopCaseTextTypeControllerFixture : IFixture<KeepOnTopCaseTextTypeController>
    {
        public KeepOnTopCaseTextTypeControllerFixture()
        {
            KeepOnTopTextTypes = Substitute.For<IKeepOnTopTextTypes>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

            Subject = new KeepOnTopCaseTextTypeController(KeepOnTopTextTypes, TaskSecurityProvider);
            CommonQueryParameters = CommonQueryParameters.Default;
            CommonQueryParameters.SortBy = null;
            CommonQueryParameters.SortDir = null;
        }

        public ICommonQueryService CommonQueryService { get; set; }
        public CommonQueryParameters CommonQueryParameters { get; set; }
        public IKeepOnTopTextTypes KeepOnTopTextTypes { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public KeepOnTopCaseTextTypeController Subject { get; set; }
    }
}
