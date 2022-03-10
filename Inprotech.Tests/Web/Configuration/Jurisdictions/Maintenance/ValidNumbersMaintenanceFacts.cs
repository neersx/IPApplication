using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class ValidNumbersMaintenanceFacts
    {
        public const string TopicName = "validNumbers";
        const string CountryCode = "AF";
        const string PropertyType = "T";
        const string PropertyType1 = "P";
        const string Pattern = "01";
        const string NumberTypeCode = "A";
        const string ErrorMessage = "Error";
        const string NewErrorMessage = "New Error Message";
        const string NewNumberTypeCode = "B";
        const string NewPropertyType = "D";
        const string NewPattern = "02";
        const int NewAdditionalValidationId = 1;
        static readonly DateTime ValidFrom = DateTime.Today;
        static readonly DateTime NewValidFrom = DateTime.Today.AddDays(-3);

        public class ValidNumbersMaintenanceFixture : IFixture<ValidNumbersMaintenance>
        {
            readonly InMemoryDbContext _db;

            public ValidNumbersMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                LastCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
                Subject = new ValidNumbersMaintenance(db, LastCodeGenerator);
            }

            public ILastInternalCodeGenerator LastCodeGenerator { get; }

            public ValidNumbersMaintenance Subject { get; set; }

            public CountryValidNumber PrepareData()
            {
                new CountryBuilder {Id = CountryCode}.Build().In(_db);
                new PropertyTypeBuilder {Id = PropertyType}.Build().In(_db);
                var numberType = new NumberTypeBuilder {Code = NumberTypeCode}.Build();
                return new CountryValidNumber(1, PropertyType, numberType.NumberTypeCode, CountryCode, Pattern, ErrorMessage) {ValidFrom = ValidFrom}.In(_db);
            }
        }

        public class ValidateMethod : FactBase
        {
            [Theory]
            [InlineData(null, null, null, null, 4)]
            [InlineData(PropertyType1, null, null, null, 3)]
            [InlineData(PropertyType1, Pattern, null, null, 2)]
            [InlineData(PropertyType1, Pattern, NumberTypeCode, null, 1)]
            public void ShouldGiveRequiredFieldMessageIfMandatoryFieldsNotProvided(string propertyType, string pattern, string numberType, string errorMesage, int noOfFieldsMissing)
            {
                var f = new ValidNumbersMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<ValidNumbersMaintenanceModel>();

                delta.Added.Add(new ValidNumbersMaintenanceModel {CountryCode = CountryCode, PropertyTypeCode = propertyType, Pattern = pattern, NumberTypeCode = numberType, DisplayMessage = errorMesage});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.True(errors.Length == noOfFieldsMissing);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Mandatory field was empty.");
            }

            [Fact]
            public void ShouldGiveDuplicateValidNumberErrorOnValidate()
            {
                var f = new ValidNumbersMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<ValidNumbersMaintenanceModel>();

                delta.Added.Add(new ValidNumbersMaintenanceModel {CountryCode = CountryCode, Pattern = Pattern, PropertyTypeCode = PropertyType, NumberTypeCode = NumberTypeCode, ValidFrom = ValidFrom, DisplayMessage = ErrorMessage});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.True(errors.Length == 1);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Duplicate Valid Numbers.");
            }
        }

        public class SaveUpdateMethod : FactBase
        {
            [Fact]
            public void ShouldAddValidNumbers()
            {
                var f = new ValidNumbersMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<ValidNumbersMaintenanceModel>();
                delta.Added.Add(new ValidNumbersMaintenanceModel
                {
                    CountryCode = CountryCode,
                    PropertyTypeCode = NewPropertyType,
                    NumberTypeCode = NewNumberTypeCode,
                    DisplayMessage = NewErrorMessage,
                    ValidFrom = NewValidFrom,
                    Pattern = NewPattern,
                    AdditionalValidationId = NewAdditionalValidationId
                });
                f.Subject.Save(delta);

                var totalTableValidNumbers = Db.Set<CountryValidNumber>().Where(_ => _.CountryId == CountryCode).ToList();
                Assert.Equal(2, totalTableValidNumbers.Count);

                var countryValidNumbers = Db.Set<CountryValidNumber>().First(_ => _.CountryId == CountryCode && _.PropertyId == NewPropertyType);

                Assert.Equal(countryValidNumbers.CountryId, CountryCode);
                Assert.Equal(countryValidNumbers.ValidFrom, NewValidFrom);
                Assert.Equal(countryValidNumbers.PropertyId, NewPropertyType);
                Assert.Equal(countryValidNumbers.NumberTypeId, NewNumberTypeCode);
                Assert.False(countryValidNumbers.WarningFlag == 1);
                Assert.Equal(countryValidNumbers.ErrorMessage, NewErrorMessage);
                Assert.Equal(countryValidNumbers.Pattern, NewPattern);
                Assert.Equal(countryValidNumbers.AdditionalValidationId, NewAdditionalValidationId);
            }

            [Fact]
            public void ShouldDeleteExistingValidNumbers()
            {
                var f = new ValidNumbersMaintenanceFixture(Db);
                var validNumber = f.PrepareData();

                var delta = new Delta<ValidNumbersMaintenanceModel>();
                delta.Deleted.Add(new ValidNumbersMaintenanceModel {Id = validNumber.Id});
                f.Subject.Save(delta);

                var totalTableValidNumbers = Db.Set<CountryValidNumber>().ToList();
                Assert.Empty(totalTableValidNumbers);
            }

            [Fact]
            public void ShouldUpdateValidNumbers()
            {
                var f = new ValidNumbersMaintenanceFixture(Db);
                var validCountry = f.PrepareData();

                var delta = new Delta<ValidNumbersMaintenanceModel>();
                delta.Updated.Add(new ValidNumbersMaintenanceModel
                {
                    Id = validCountry.Id,
                    CountryCode = validCountry.CountryId,
                    PropertyTypeCode = NewPropertyType,
                    NumberTypeCode = NewNumberTypeCode,
                    WarningFlag = true,
                    DisplayMessage = NewErrorMessage,
                    ValidFrom = NewValidFrom,
                    AdditionalValidationId = NewAdditionalValidationId
                });
                f.Subject.Save(delta);
                var countryValidNumbers = Db.Set<CountryValidNumber>().First(_ => _.Id == validCountry.Id);

                Assert.NotNull(countryValidNumbers);

                Assert.Equal(countryValidNumbers.CountryId, CountryCode);
                Assert.Equal(countryValidNumbers.ValidFrom, NewValidFrom);
                Assert.Equal(countryValidNumbers.PropertyId, NewPropertyType);
                Assert.Equal(countryValidNumbers.NumberTypeId, NewNumberTypeCode);
                Assert.True(countryValidNumbers.WarningFlag == 1);
                Assert.Equal(countryValidNumbers.ErrorMessage, NewErrorMessage);
                Assert.Equal(countryValidNumbers.AdditionalValidationId, NewAdditionalValidationId);
            }
        }
    }
}