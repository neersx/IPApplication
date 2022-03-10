using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.ExchangeRateVariations;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ExchangeRateVariations
{
    public class ExchangeRateVariationControllerFacts
    {
        public class ExchangeRateVariationControllerFixture : IFixture<ExchangeRateVariationController>
        {
            public ExchangeRateVariationControllerFixture()
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                ExchangeRateVariation = Substitute.For<IExchangeRateVariations>();

                Subject = new ExchangeRateVariationController(TaskSecurityProvider, ExchangeRateVariation);
                CommonQueryParameters = CommonQueryParameters.Default;
                CommonQueryParameters.SortBy = null;
                CommonQueryParameters.SortDir = null;
            }

            public ICommonQueryService CommonQueryService { get; set; }
            public CommonQueryParameters CommonQueryParameters { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public IExchangeRateVariations ExchangeRateVariation { get; set; }
            public ExchangeRateVariationController Subject { get; set; }
        }

        public class ViewData : FactBase
        {
            [Fact]
            public void ShouldReturnAppropriatePermissionWhenCurrencyType()
            {
                var f = new ExchangeRateVariationControllerFixture();
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Modify).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Delete).Returns(false);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCurrency, ApplicationTaskAccessLevel.Create).Returns(true);

                var res = f.Subject.ViewData("CUR");

                Assert.Equal(res.CanAdd, true);
                Assert.Equal(res.CanDelete, false);
                Assert.Equal(res.CanEdit, true);
            }

            [Fact]
            public void ShouldReturnAppropriatePermissionWhenExchangeRateScheduleType()
            {
                var f = new ExchangeRateVariationControllerFixture();
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Modify).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Delete).Returns(false);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainExchangeRatesSchedule, ApplicationTaskAccessLevel.Create).Returns(true);

                var res = f.Subject.ViewData("EXS");

                Assert.Equal(res.CanAdd, true);
                Assert.Equal(res.CanDelete, false);
                Assert.Equal(res.CanEdit, true);
            }
        }

        public class GetExchangeRateVariation : FactBase
        {

            [Fact]
            public void SearchReturnAll()
            {
                var f = new ExchangeRateVariationControllerFixture();
                var filter = new ExchangeRateVariationsFilterModel();

                var results = new List<ExchangeRateVariationsResult> { new ExchangeRateVariationsResult() };

                f.ExchangeRateVariation.GetExchangeRateVariations(filter).Returns(results);

                f.Subject.GetExchangeRateVariations(filter, f.CommonQueryParameters);
                f.ExchangeRateVariation.Received(1).GetExchangeRateVariations(filter);
            }
        }

        public class DeleteExchangeRateVariations : FactBase
        {
            [Fact]
            public async Task ShouldDelete()
            {
                var f = new ExchangeRateVariationControllerFixture();
                f.ExchangeRateVariation.Delete(Arg.Any<DeleteRequestModel>()).Returns(new DeleteResponseModel { Message = "success" });
                var response = await f.Subject.Delete(new DeleteRequestModel());
                Assert.Equal("success", response.Message);
                await f.ExchangeRateVariation.Received(1).Delete(Arg.Any<DeleteRequestModel>());
            }

            [Fact]
            public async Task ShouldReturnError()
            {
                var f = new ExchangeRateVariationControllerFixture();
                f.ExchangeRateVariation.Delete(Arg.Any<DeleteRequestModel>()).Throws(new HttpResponseException(HttpStatusCode.NotFound));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => { await f.Subject.Delete(new DeleteRequestModel()); });
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }

        public class GetExchangeRateVariationDetails : FactBase
        {
            [Fact]
            public async Task ShouldGetExchangeRateVariationDetails()
            {
                var f = new ExchangeRateVariationControllerFixture();
                var param = Fixture.Integer();
                await f.Subject.GetExchangeRateVariationDetails(param);
                await f.ExchangeRateVariation.Received(1).GetExchangeRateVariationDetails(param);
            }
        }

        public class ExchangeRateVariationValidation : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorInAddWhenDataNotExist()
            {
                var f = new ExchangeRateVariationControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.ValidateDuplicateExchangeVariation(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldValidateExchangeRateVariation()
            {
                var f = new ExchangeRateVariationControllerFixture();
                f.ExchangeRateVariation.ValidateDuplicateExchangeVariation(Arg.Any<ExchangeRateVariationRequest>()).Returns(new Inprotech.Infrastructure.Validations.ValidationError("currencyCode", "Duplicate"));
                var result = await f.Subject.ValidateDuplicateExchangeVariation(new ExchangeRateVariationRequest());
                await f.ExchangeRateVariation.Received(1).ValidateDuplicateExchangeVariation(Arg.Any<ExchangeRateVariationRequest>());
                Assert.Equal("currencyCode", result.Field);
                Assert.Equal("Duplicate", result.Message);
            }
        }

        public class SaveExchangeRateVariation : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorInAddWhenDataNotExist()
            {
                var f = new ExchangeRateVariationControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.AddExchangeRateVariation(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldSaveExchangeRateVariation()
            {
                var f = new ExchangeRateVariationControllerFixture();
                var data = new ExchangeRateVariationRequest();
                f.ExchangeRateVariation.SubmitExchangeRateVariation(data).Returns(1);
                var result = await f.Subject.AddExchangeRateVariation(data);
                Assert.Equal(result, 1);
                await f.ExchangeRateVariation.Received(1).SubmitExchangeRateVariation(data);
            }

            [Fact]
            public async Task ShouldUpdateExchangeRateVariation()
            {
                var f = new ExchangeRateVariationControllerFixture();
                var data = new ExchangeRateVariationRequest()
                {
                    Id = Fixture.Integer(),
                    CurrencyCode = Fixture.String(),
                    SellFactor = Fixture.Integer(),
                    BuyFactor = Fixture.Integer()

                };
                f.ExchangeRateVariation.SubmitExchangeRateVariation(data).Returns(1);
                var result = await f.Subject.UpdateExchangeRateVariation(data);
                Assert.Equal(result, 1);
                await f.ExchangeRateVariation.Received(1).SubmitExchangeRateVariation(data);
            }

            [Fact]
            public async Task ShouldThrowErrorInUpdateWhenDataNotExist()
            {
                var f = new ExchangeRateVariationControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.AddExchangeRateVariation(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }
        }
    }
}
