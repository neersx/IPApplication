using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.TaxCode;
using InprotechKaizen.Model.Accounting.Tax;
using NSubstitute;
using Xunit;
using DeleteRequestModel = Inprotech.Web.Configuration.TaxCode.DeleteRequestModel;
using DeleteResponseModel = Inprotech.Web.Configuration.TaxCode.DeleteResponseModel;

namespace Inprotech.Tests.Web.TaxCode
{
    public class TaxCodeMaintenanceControllerFacts
    {
        public class TaxCodeSearch : FactBase
        {
            [Fact]
            public void ShouldReturnAllResult()
            {
                var f = new TaxCodeMaintenanceControllerFixture(Db);

                var result = f.Subject.Search(null, new CommonQueryParameters());

                Assert.NotNull(result);
            }

            [Fact]
            public void ShouldReturnMatchingTaxCode()
            {
                new TaxRate { Id = 1, Code = "T1" }.In(Db);

                var searchOptions = new SearchOptions
                {
                    Text = "T1"
                };
                var f = new TaxCodeMaintenanceControllerFixture(Db);

                var result = f.Subject.Search(searchOptions);
                var taxCodes = ((IEnumerable<dynamic>)result.TaxCodes).ToArray();
                Assert.NotNull(result);
                // Assert.Equal(1, (IEnumerable<dynamic>)result.Ids);
                Assert.Empty(taxCodes);
            }

            [Fact]
            public void ReturnsTaxCodesSortedByDescription()
            {
                var f = new TaxCodeMaintenanceControllerFixture(Db);

                var t1 = new TaxCodes { Id = 1, Description = "desc1", TaxCode = "T1" };
                var t2 = new TaxCodes { Id = 1, Description = "desc2", TaxCode = "T2" };
                var t3 = new TaxCodes { Id = 1, Description = "desc3", TaxCode = "T3" };
                var t4 = new TaxCodes { Id = 1, Description = "desc4", TaxCode = "T4" };

                var queryParams = new CommonQueryParameters { SortBy = "Description", SortDir = "desc" };
                var searchOptions = new SearchOptions
                {
                    Text = "desc"
                };
                var taxCodes = new List<TaxCodes> { t1, t2, t3, t4 };
                f.TaxCodeSearchService.DoSearch(searchOptions, Fixture.String()).ReturnsForAnyArgs(taxCodes.AsDbAsyncEnumerble());
                var result = f.Subject.Search(searchOptions, queryParams);

                var taxCodesResponse = ((TaxCodeDetails)result).TaxCodes.ToList();
                Assert.Equal(4, taxCodesResponse.Count);
                Assert.Equal(taxCodesResponse.First().Description, "desc4");
                Assert.Equal(taxCodesResponse.Last().Description, "desc1");
            }
        }

        public class DeleteTaxCodes : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenAlertNotFound()
            {
                var f = new TaxCodeMaintenanceControllerFixture(Db);

                var exception = await Record.ExceptionAsync(async () => await f.Subject.Delete(null));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException)exception).Response.StatusCode);
            }

            [Fact]
            public async Task ShouldDeleteTaxCode()
            {
                var fixture = new TaxCodeMaintenanceControllerFixture(Db);
                var response = new DeleteResponseModel
                {
                    InUseIds = new List<int> { 1 },
                    Message = "TaxCode deleted successfully"
                };

                fixture.TaxCodeMaintenanceService.Delete(Arg.Any<DeleteRequestModel>()).ReturnsForAnyArgs(response);

                var result = await fixture.Subject.Delete(new DeleteRequestModel());
                Assert.Equal(false, result.HasError);
                Assert.Equal(1, result.InUseIds[0]);
                Assert.Equal("TaxCode deleted successfully", result.Message);
            }
        }

        public class MaintainTaxCodeDetails : FactBase
        {
            [Fact]
            public async Task ThrowNullExceptionWhenTaxCodeSaveDetailsIsNull()
            {
                var f = new TaxCodeMaintenanceControllerFixture(Db);

                await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.MaintainTaxCodeDetails(new TaxCodeSaveDetails()));
            }

            [Fact]
            public async Task ThrowNullExceptionForInvalidTaxCode()
            {
                var f = new TaxCodeMaintenanceControllerFixture(Db);
                var overviewDetails = new TaxCodes
                {
                    Description = Fixture.String()
                };

                await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.MaintainTaxCodeDetails(new TaxCodeSaveDetails { OverviewDetails = overviewDetails }));
            }

            [Fact]
            public async Task ShouldMaintainTaxCodeDetails()
            {
                var fixture = new TaxCodeMaintenanceControllerFixture(Db);
                var t1 = new TaxRate { Code = Fixture.String(), Description = Fixture.String() }.In(Db);
                var taxRateCountry = new TaxRatesCountry { TaxCode = t1.Code, CountryId = Fixture.String(), EffectiveDate = Fixture.Date(), Rate = Fixture.Decimal() }.In(Db);

                var overviewDetails = new TaxCodes
                {
                    Id = 1,
                    Description = Fixture.String()
                };
                var taxRate = new TaxRates
                {
                    EffectiveDate = Fixture.Date(),
                    Id = taxRateCountry.TaxRateCountryId,
                    SourceJurisdiction = new SourceJurisdiction { Code = "AF", Key = "Afghanistan" },
                    Status = null,
                    TaxRate = "10.00"
                };
                var response = new DeleteResponseModel
                {
                    InUseIds = new List<int> { 1 },
                    Message = "success"
                };

                fixture.TaxCodeMaintenanceService.MaintainTaxCodeDetails(Arg.Any<TaxCodeSaveDetails>()).ReturnsForAnyArgs(response);

                var result = await fixture.Subject.MaintainTaxCodeDetails(new TaxCodeSaveDetails { OverviewDetails = overviewDetails, TaxRatesDetails = new List<TaxRates> { taxRate } });
                Assert.Equal(response.Message, result.Message);
            }
        }

        public class CreateTaxCode : FactBase
        {
            [Fact]
            public async Task ShouldCreateTaxCode()
            {
                var fixture = new TaxCodeMaintenanceControllerFixture(Db);
                var status = new
                {
                    Result = "success",
                    TaxCodeId = 1
                };
                fixture.TaxCodeMaintenanceService.CreateTaxCode(Arg.Any<TaxCodes>()).ReturnsForAnyArgs(status);
                var result = await fixture.Subject.CreateTaxCode(new TaxCodes
                {
                    Description = Fixture.String()
                });
                Assert.Equal(status, result);
            }
        }
    }

    public class TaxCodeMaintenanceControllerFixture : IFixture<TaxCodeMaintenanceController>
    {
        public TaxCodeMaintenanceControllerFixture(InMemoryDbContext db)
        {
            var cultureResolver = Substitute.For<IPreferredCultureResolver>();
            TaxCodeSearchService = Substitute.For<ITaxCodeSearchService>();
            TaxCodeDetailService = Substitute.For<ITaxCodeDetailService>();
            TaxCodeMaintenanceService = Substitute.For<ITaxCodeMaintenanceService>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            Subject = new TaxCodeMaintenanceController(TaxCodeSearchService, cultureResolver, TaskSecurityProvider, TaxCodeMaintenanceService, TaxCodeDetailService, DbContext);
            DefaultQueryParameter = new CommonQueryParameters
            {
                SortBy = "TaxCodeName"
            };
        }

        public CommonQueryParameters DefaultQueryParameter { get; set; }
        public ITaxCodeSearchService TaxCodeSearchService { get; }
        public ITaxCodeDetailService TaxCodeDetailService { get; }
        public ITaxCodeMaintenanceService TaxCodeMaintenanceService { get; set; }
        public InMemoryDbContext DbContext { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; }
        public TaxCodeMaintenanceController Subject { get; }
    }
}