using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.KeepOnTopNotes;
using InprotechKaizen.Model;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.KeepOnTopNotes
{
    public class KeepOnTopNameTextTypeControllerFacts
    {
        public class GetKotTextTypes : FactBase
        {
            [Fact]
            public void ReturnsAllKotNameTextTypes()
            {
                var f = new KeepOnTopNameTextTypeControllerFixture();
                var data = new List<KotTextType>
                {
                    new KotTextType
                    {
                        Id = Fixture.Integer(),
                        Modules = Fixture.String(),
                        NameTypes = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        TextType = Fixture.String("Dbc")
                    },
                    new KotTextType
                    {
                        Id = Fixture.Integer(),
                        Modules = Fixture.String(),
                        NameTypes = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        TextType = Fixture.String("Bcd")
                    }
                };
                f.KeepOnTopTextTypes.GetKotTextTypes(KnownKotTypes.Name).Returns(data);
                var r = f.Subject.GetKeepOnTopNameTextTypes(null, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>)r).ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(data[1].TextType, results[0].TextType);
            }

            [Fact]
            public void ReturnsFilteredKotNameTextTypes()
            {
                var f = new KeepOnTopNameTextTypeControllerFixture();
                var data = new List<KotTextType>
                {
                    new KotTextType
                    {
                        Id = Fixture.Integer(),
                        Modules = "abc",
                        NameTypes = Fixture.String(),
                        BackgroundColor = Fixture.String(),
                        TextType = Fixture.String("Bcd")
                    }
                };
                var options = new KeepOnTopSearchOptions()
                {
                    Modules = "mod, abc".Split(','),
                    Statuses = "dead, pending".Split(','),
                };
                f.KeepOnTopTextTypes.GetKotTextTypes(KnownKotTypes.Name, options).Returns(data);
                var r = f.Subject.GetKeepOnTopNameTextTypes(options, f.CommonQueryParameters);
                var results = ((IEnumerable<dynamic>)r).ToArray();

                Assert.Equal(1, results.Length);
            }
        }

        public class GetKotTextTypeDetails : FactBase
        {
            [Fact]
            public async Task ShouldGetNameKotTextType()
            {
                var f = new KeepOnTopNameTextTypeControllerFixture();

                await f.Subject.GetKeepOnTopTextTypeNameDetails(1);
                await f.KeepOnTopTextTypes.Received(1).GetKotTextTypeDetails(1, KnownKotTypes.Name);
            }
        }

        public class SaveKotTextType : FactBase
        {
            [Fact]
            public async Task ShouldSaveNameKotTextType()
            {
                var f = new KeepOnTopNameTextTypeControllerFixture();
                var kotData = new KotTextTypeData();
                var response = new KotSaveResponse { Id = Fixture.Integer() };
                f.KeepOnTopTextTypes.SaveKotTextType(kotData, KnownKotTypes.Name).Returns(response);
                var result = await f.Subject.SaveKeepOnTopNameTextType(kotData);
                Assert.Equal(result.Id, response.Id);
                await f.KeepOnTopTextTypes.Received(1).SaveKotTextType(kotData, KnownKotTypes.Name);
            }
        }

        public class DeleteNameKotTextType : FactBase
        {
            [Fact]
            public async Task ShouldDeleteKotTextType()
            {
                var f = new KeepOnTopNameTextTypeControllerFixture();
                f.KeepOnTopTextTypes.DeleteKotTextType(Arg.Any<int>()).Returns(new DeleteResponse { Result = "success" });
                var response = await f.Subject.DeleteKeepOnTopTextType(Fixture.Integer());
                Assert.Equal("success", response.Result);
                await f.KeepOnTopTextTypes.Received(1).DeleteKotTextType(Arg.Any<int>());
            }

            [Fact]
            public async Task ShouldReturnError()
            {
                var f = new KeepOnTopNameTextTypeControllerFixture();
                f.KeepOnTopTextTypes.DeleteKotTextType(Arg.Any<int>()).Throws(new HttpResponseException(HttpStatusCode.NotFound));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () =>
                {
                    await f.Subject.DeleteKeepOnTopTextType(Fixture.Integer());
                });
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }
    }

    public class KeepOnTopNameTextTypeControllerFixture : IFixture<KeepOnTopNameTextTypeController>
    {
        public KeepOnTopNameTextTypeControllerFixture()
        {
            KeepOnTopTextTypes = Substitute.For<IKeepOnTopTextTypes>();

            Subject = new KeepOnTopNameTextTypeController(KeepOnTopTextTypes);
            CommonQueryParameters = CommonQueryParameters.Default;
            CommonQueryParameters.SortBy = null;
            CommonQueryParameters.SortDir = null;
        }

        public ICommonQueryService CommonQueryService { get; set; }
        public CommonQueryParameters CommonQueryParameters { get; set; }
        public IKeepOnTopTextTypes KeepOnTopTextTypes { get; set; }
        public KeepOnTopNameTextTypeController Subject { get; set; }
    }
}
