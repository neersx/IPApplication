using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Offices;
using Inprotech.Web.Picklists;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Offices
{
    public class OfficeControllerFacts
    {
        public class OfficeControllerFixture : IFixture<OfficeController>
        {
            public OfficeControllerFixture()
            {
                Offices = Substitute.For<IOffices>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                Subject = new OfficeController(Offices, TaskSecurityProvider);
                CommonQueryParameters = CommonQueryParameters.Default;
                CommonQueryParameters.SortBy = null;
                CommonQueryParameters.SortDir = null;
            }

            public ICommonQueryService CommonQueryService { get; set; }
            public CommonQueryParameters CommonQueryParameters { get; set; }
            public IOffices Offices { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public OfficeController Subject { get; set; }
        }

        public class GetOffices : FactBase
        {
            static List<Office> Offices()
            {
                var data = new List<Office>
                {
                    new Office
                    {
                        Key = Fixture.Integer(),
                        Value = Fixture.String("DRV"),
                        Organisation = Fixture.String(),
                        Country = Fixture.String(),
                        DefaultLanguage = Fixture.String()
                    },
                    new Office
                    {
                        Key = Fixture.Integer(),
                        Value = Fixture.String("ABC"),
                        Organisation = Fixture.String(),
                        Country = Fixture.String(),
                        DefaultLanguage = Fixture.String()
                    }
                };
                return data;
            }

            [Fact]
            public async Task ReturnsAllOffices()
            {
                var f = new OfficeControllerFixture();
                var data = Offices();
                f.Offices.GetOffices(Arg.Any<string>()).Returns(data);
                var r = await f.Subject.GetOffices(new SearchOptions(), f.CommonQueryParameters);
                var results = r.ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(data[1].Value, results[0].Value);
            }
        }

        public class GetOfficeDetails : FactBase
        {
            [Fact]
            public async Task ShouldGetOffice()
            {
                var f = new OfficeControllerFixture();

                await f.Subject.GetOffice(1);
                await f.Offices.Received(1).GetOffice(1);
            }
        }

        public class SaveOffice : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorInAddWhenDataNotExist()
            {
                var f = new OfficeControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.AddOffice(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldThrowErrorInUpdateWhenDataNotExist()
            {
                var f = new OfficeControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.UpdateOffice(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldUpdateOffice()
            {
                var f = new OfficeControllerFixture();
                var data = new OfficeData { Id = Fixture.Integer()};
                var response = new OfficeSaveResponse { Id = Fixture.Integer() };
                f.Offices.SaveOffice(data).Returns(response);
                var result = await f.Subject.UpdateOffice(data);
                Assert.Equal(result.Id, response.Id);
                await f.Offices.Received(1).SaveOffice(data);
            }

            [Fact]
            public async Task ShouldAddOffice()
            {
                var f = new OfficeControllerFixture();
                var data = new OfficeData();
                var response = new OfficeSaveResponse { Id = Fixture.Integer() };
                f.Offices.SaveOffice(data).Returns(response);
                var result = await f.Subject.UpdateOffice(data);
                Assert.Equal(result.Id, response.Id);
                await f.Offices.Received(1).SaveOffice(data);
            }
        }

        public class DeleteOffice : FactBase
        {
            [Fact]
            public async Task ShouldDeleteOffice()
            {
                var f = new OfficeControllerFixture();
                f.Offices.Delete(Arg.Any<DeleteRequestModel>()).Returns(new DeleteResponseModel {Message = "success"});
                var response = await f.Subject.Delete(new DeleteRequestModel());
                Assert.Equal("success", response.Message);
                await f.Offices.Received(1).Delete(Arg.Any<DeleteRequestModel>());
            }

            [Fact]
            public async Task ShouldReturnError()
            {
                var f = new OfficeControllerFixture();
                f.Offices.Delete(Arg.Any<DeleteRequestModel>()).Throws(new HttpResponseException(HttpStatusCode.NotFound));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () =>
                {
                    await f.Subject.Delete(new DeleteRequestModel());
                });
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }

        public class GetOfficePermissions : FactBase
        {
            [Fact]
            public void ShouldCheckOfficePermission()
            {
                var f = new OfficeControllerFixture();

                var r = f.Subject.ViewData();
                Assert.False(r.CanAdd);
                Assert.False(r.CanDelete);
                Assert.False(r.CanEdit);
            }
        }
    }
}
