using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.ExchangeRateSchedule;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;
using static Inprotech.Web.Picklists.ExchangeRateSchedulePicklistController;

namespace Inprotech.Tests.Web.Configuration.ExchangeRateSchedule
{
    public class ExchangeRateScheduleControllerFacts
    {
        public class ExchangeRateScheduleControllerFixture : IFixture<ExchangeRateScheduleController>
        {
            public ExchangeRateScheduleControllerFixture()
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                ExchangeRateScheduleService = Substitute.For<IExchangeRateScheduleService>();

                Subject = new ExchangeRateScheduleController(TaskSecurityProvider, ExchangeRateScheduleService);
                CommonQueryParameters = CommonQueryParameters.Default;
                CommonQueryParameters.SortBy = null;
                CommonQueryParameters.SortDir = null;
            }

            public CommonQueryParameters CommonQueryParameters { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public IExchangeRateScheduleService ExchangeRateScheduleService { get; set; }
            public ExchangeRateScheduleController Subject { get; set; }
        }

        public class ViewData : FactBase
        {
            [Fact]
            public void ShouldReturnAppropriatePermission()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Modify).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Delete).Returns(false);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Create).Returns(true);

                var res = f.Subject.ViewData();

                Assert.Equal(res.CanAdd, true);
                Assert.Equal(res.CanDelete, false);
                Assert.Equal(res.CanEdit, true);
            }
        }

        public class GetExchangeRateSchedule : FactBase
        {
            static List<ExchangeRateSchedulePicklistItem> ExchangeRateSchedule()
            {
                var data = new List<ExchangeRateSchedulePicklistItem>
                {
                    new ExchangeRateSchedulePicklistItem
                    {
                        Code = Fixture.String("AA"),
                        Description = Fixture.String("AA")
                    },
                    new ExchangeRateSchedulePicklistItem
                    {
                        Code = Fixture.String("BB"),
                        Description = Fixture.String("BB")
                    }
                };
                return data;
            }

            [Fact]
            public async Task ShouldReturnAllExchangeRateSchedule()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                var data = ExchangeRateSchedule();

                f.ExchangeRateScheduleService.GetExchangeRateSchedule().Returns(data);
                var r = await f.Subject.GetExchangeRateSchedule(new SearchOptions(), null);
                var results = r.Items<ExchangeRateSchedulePicklistItem>().ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(data[0].Description, results[0].Description);
                Assert.Equal(data[1].Code, results[1].Code);
            }

            [Fact]
            public async Task ShouldReturnMatchingExchangeRateSchedule()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                var data = ExchangeRateSchedule();

                f.ExchangeRateScheduleService.GetExchangeRateSchedule().Returns(data);
                var r = await f.Subject.GetExchangeRateSchedule(new SearchOptions {Text = "AA"}, null);
                var results = r.Items<ExchangeRateSchedulePicklistItem>().ToArray();

                Assert.Equal(1, results.Length);
                Assert.Equal(data[0].Description, results[0].Description);
            }
        }

        public class GetExchangeRateScheduleDetails : FactBase
        {
            [Fact]
            public async Task ShouldGetExchangeRateSchedule()
            {
                var f = new ExchangeRateScheduleControllerFixture();

                await f.Subject.GetExchangeRateScheduleDetails(1);
                await f.ExchangeRateScheduleService.Received(1).GetExchangeRateScheduleDetails(1);
            }
        }

        public class ValidateExistingCode
        {
            [Fact]
            public async Task ShouldThrowErrorInAddWhenCodeNotExist()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.ValidateExistingCode(null); });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldCallValidate()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                var data = new ExchangeRateSchedulePicklistItem();
                var result = await f.Subject.ValidateExistingCode("ABC");
                await f.ExchangeRateScheduleService.Received(1).ValidateExistingCode("ABC");
            }
        }

        public class SaveExchangeRateSchedule : FactBase
        {
            [Fact]
            public async Task ShouldSaveExchangeRateSchedule()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                var data = new ExchangeRateSchedulePicklistItem();
                f.ExchangeRateScheduleService.SubmitExchangeRateSchedule(data).Returns("ABC");
                var result = await f.Subject.AddExchangeRateSchedule(data);
                Assert.Equal(result, "ABC");
                await f.ExchangeRateScheduleService.Received(1).SubmitExchangeRateSchedule(data);
            }

            [Fact]
            public async Task ShouldThrowErrorInAddWhenDataNotExist()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.AddExchangeRateSchedule(null); });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldThrowErrorInUpdateWhenDataNotExist()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.UpdateExchangeRateSchedule(null); });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldUpdateExchangeRateSchedule()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                var data = new ExchangeRateSchedulePicklistItem
                {
                    Id = Fixture.Integer(),
                    Code = Fixture.String(),
                    Description = Fixture.String()
                };
                f.ExchangeRateScheduleService.SubmitExchangeRateSchedule(data).Returns("UPD");
                var result = await f.Subject.UpdateExchangeRateSchedule(data);
                Assert.Equal(result, "UPD");
                await f.ExchangeRateScheduleService.Received(1).SubmitExchangeRateSchedule(data);
            }
        }

        public class DeleteExchangeRateSchedules : FactBase
        {
            [Fact]
            public async Task ShouldReturnArgumentNullError()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.DeleteExchangeRateSchedules(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldDelete()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                f.ExchangeRateScheduleService.Delete(Arg.Any<DeleteRequestModel>()).Returns(new DeleteResponseModel {Message = "success"});
                var response = await f.Subject.DeleteExchangeRateSchedules(new DeleteRequestModel());
                Assert.Equal("success", response.Message);
                await f.ExchangeRateScheduleService.Received(1).Delete(Arg.Any<DeleteRequestModel>());
            }

            [Fact]
            public async Task ShouldReturnError()
            {
                var f = new ExchangeRateScheduleControllerFixture();
                f.ExchangeRateScheduleService.Delete(Arg.Any<DeleteRequestModel>()).Throws(new HttpResponseException(HttpStatusCode.NotFound));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () =>
                {
                    await f.Subject.DeleteExchangeRateSchedules(new DeleteRequestModel());
                });
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }
    }
}