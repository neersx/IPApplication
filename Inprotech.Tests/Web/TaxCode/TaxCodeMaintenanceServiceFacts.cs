using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Configuration.TaxCode;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.TaxCode
{
    public class TaxCodeMaintenanceServiceFacts : FactBase
    {
        public class DeleteTaxCodes : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenTaxCodeNotFound()
            {
                var f = new TaxCodesMaintenanceServiceFixture(Db);

                var exception = await Record.ExceptionAsync(async () => await f.Subject.Delete(null));

                Assert.NotNull(exception);
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldDeleteTaxCode()
            {
                new TaxRate { Id = 1, Code = Fixture.String() }.In(Db);
                new TaxRate { Id = 2, Code = Fixture.String() }.In(Db);
                var f = new TaxCodesMaintenanceServiceFixture(Db);

                var deleteRequest = new DeleteRequestModel
                {
                    Ids = new List<int> { 1 }
                };

                var result = await f.Subject.Delete(deleteRequest);

                Assert.Equal(false, result.HasError);
            }

            [Fact]
            public async Task ShouldBulkDeleteTaxCodes()
            {
                new TaxRate("1") { Code = Fixture.String() }.In(Db);
                new TaxRate("2") { Code = Fixture.String() }.In(Db);
                new TaxRate("3") { Code = Fixture.String() }.In(Db);
                new TaxRate("4") { Code = Fixture.String() }.In(Db);
                new TaxRate("5") { Code = Fixture.String() }.In(Db);
                var f = new TaxCodesMaintenanceServiceFixture(Db);

                var deleteRequest = new DeleteRequestModel
                {
                    Ids = new List<int> { 1, 2, 3, 4, 5 }
                };

                var result = await f.Subject.Delete(deleteRequest);

                Assert.Equal(false, result.HasError);
            }
        }

        public class CreateTaxCodes : FactBase
        {
            [Fact]
            public async Task ThrowNullExceptionWhenSaveTaxCodesIsNull()
            {
                var f = new TaxCodesMaintenanceServiceFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.CreateTaxCode(null));
            }

            [Fact]
            public async Task ShouldCreateTaxCodes()
            {
                var f = new TaxCodesMaintenanceServiceFixture(Db);

                var saveTaxCodes = new TaxCodes
                {
                    TaxCode = Fixture.String(),
                    Description = Fixture.String(),
                    Id = Fixture.Integer()
                };
                f.WithValidation();
                var result = await f.Subject.CreateTaxCode(saveTaxCodes);
                Assert.Equal(1, result.TaxRateId);
            }

            [Fact]
            public async Task ShouldReturnErrorWhenTaxCodesIsAlreadyExists()
            {
                var f = new TaxCodesMaintenanceServiceFixture(Db);
                new TaxRate { Code = "T1", Description = "Desc" }.In(Db);

                var overviewDetails = new TaxCodes
                {
                    TaxCode = "T1",
                    Id = 1
                };
                f.WithUniqueValidationError("taxcode");
                var result = await f.Subject.CreateTaxCode(overviewDetails);
                Assert.NotNull(result.Errors);
                Assert.Single((IEnumerable<ValidationError>)result.Errors);
                Assert.Equal("taxcode", ((IEnumerable<ValidationError>)result.Errors).First().Field);
                Assert.Equal("field.errors.notunique", ((IEnumerable<ValidationError>)result.Errors).First().Message);
            }
        }

        public class MaintainTaxCode : FactBase
        {
            [Fact]
            public async Task ThrowNullExceptionWhenTaxCodeAndTaxRateDetailsAreNull()
            {
                var f = new TaxCodesMaintenanceServiceFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.MaintainTaxCodeDetails(new TaxCodeSaveDetails()));
            }

            [Fact]
            public async Task ShouldAddTaxRatesForJurisdiction()
            {
                var f = new TaxCodesMaintenanceServiceFixture(Db);
                new TaxRate { Code = Fixture.String(), Description = Fixture.String() }.In(Db);

                var overviewDetails = new TaxCodes
                {
                    Id = 1,
                    Description = Fixture.String()
                };
                var taxRate1 = new TaxRates
                {
                    EffectiveDate = Fixture.Date(),
                    SourceJurisdiction = new SourceJurisdiction { Code = "AF", Key = "Afghanistan" },
                    Status = "A",
                    TaxRate = "10.00"
                };
                var taxRate2 = new TaxRates
                {
                    EffectiveDate = Fixture.Date(),
                    SourceJurisdiction = new SourceJurisdiction { Code = "IN", Key = "India" },
                    Status = "A",
                    TaxRate = "5.00"
                };
                var response = new DeleteResponseModel
                {
                    Message = "success"
                };

                var result = await f.Subject.MaintainTaxCodeDetails(new TaxCodeSaveDetails { OverviewDetails = overviewDetails, TaxRatesDetails = new List<TaxRates> { taxRate1, taxRate2 } });
                var ids = Db.Set<TaxRatesCountry>().Select(_ => _.TaxRateCountryId);
                Assert.Equal(response.Message, result.Message);
            }

            [Fact]
            public async Task ShouldDeleteTaxRates()
            {
                var fixture = new TaxCodesMaintenanceServiceFixture(Db);
                var tc = new TaxRate { Code = Fixture.String(), Description = Fixture.String() }.In(Db);
                var t1 = new TaxRatesCountry { TaxRateCountryId = 1, TaxCode = tc.Code, CountryId = Fixture.String(), EffectiveDate = Fixture.Date(), Rate = Fixture.Decimal() }.In(Db);
                new TaxRatesCountry { TaxRateCountryId = 2, TaxCode = tc.Code, CountryId = Fixture.String(), EffectiveDate = Fixture.Date(), Rate = Fixture.Decimal() }.In(Db);

                var overviewDetails = new TaxCodes
                {
                    Id = 1,
                    Description = Fixture.String()
                };
                var taxRate = new TaxRates
                {
                    Id = 1,
                    EffectiveDate = t1.EffectiveDate,
                    Status = "D",
                    TaxRate = t1.Rate.ToString()
                };
                var response = new DeleteResponseModel
                {
                    InUseIds = new List<int> { 1 },
                    Message = "success"
                };

                var result = await fixture.Subject.MaintainTaxCodeDetails(new TaxCodeSaveDetails { OverviewDetails = overviewDetails, TaxRatesDetails = new List<TaxRates> { taxRate } });
                Assert.Equal(response.Message, result.Message);
            }

            [Fact]
            public async Task ShouldMaintainTaxRateDetails()
            {
                var fixture = new TaxCodesMaintenanceServiceFixture(Db);
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
                    Message = "success"
                };

                var result = await fixture.Subject.MaintainTaxCodeDetails(new TaxCodeSaveDetails { OverviewDetails = overviewDetails, TaxRatesDetails = new List<TaxRates> { taxRate } });

                Assert.Equal(response.Message, result.Message);
            }

            [Fact]
            public async Task ShouldMaintainTaxCodeDetails()
            {
                var fixture = new TaxCodesMaintenanceServiceFixture(Db);
                new TaxRate { Code = Fixture.String(), Description = Fixture.String() }.In(Db);

                var overviewDetails = new TaxCodes
                {
                    Id = 1,
                    Description = Fixture.String()
                };
                var response = new DeleteResponseModel
                {
                    Message = "success"
                };

                var result = await fixture.Subject.MaintainTaxCodeDetails(new TaxCodeSaveDetails { OverviewDetails = overviewDetails });

                Assert.Equal(response.Message, result.Message);
            }
        }
    }

    public class TaxCodesMaintenanceServiceFixture : IFixture<ITaxCodeMaintenanceService>
    {
        public TaxCodesMaintenanceServiceFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            TaxCodeValidator = Substitute.For<ITaxCodesValidator>();
            Subject = new TaxCodeMaintenanceService(db, TaxCodeValidator);
            SecurityContext.User.Returns(new User(Fixture.String(), false));
        }

        public ISecurityContext SecurityContext { get; set; }
        public ITaxCodesValidator TaxCodeValidator { get; set; }
        public ITaxCodeMaintenanceService Subject { get; }

        public TaxCodesMaintenanceServiceFixture WithValidation()
        {
            TaxCodeValidator.Validate(Arg.Any<string>(), Arg.Any<Operation>()).Returns(Enumerable.Empty<ValidationError>());
            return this;
        }

        public TaxCodesMaintenanceServiceFixture WithUniqueValidationError(string forField)
        {
            TaxCodeValidator.Validate(Arg.Any<string>(), Arg.Any<Operation>()).Returns(new[] { ValidationErrors.NotUnique(forField) });
            return this;
        }
    }
}