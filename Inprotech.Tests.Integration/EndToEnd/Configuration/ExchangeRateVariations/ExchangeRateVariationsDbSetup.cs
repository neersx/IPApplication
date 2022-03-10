using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.ExchangeRateVariations
{
    public class ExchangeRateVariationsDbSetup : DbSetup
    {
        internal const string ValidPropertyTypeDescription = "e2e - valid property type";
        internal const string ValidCaseCategoryDescription = "e2e - valid case category";
        internal const string ValidSubTypeDescription = "e2e - valid sub type";
        public dynamic Setup()
        {
            var caseType = InsertWithNewId(new CaseType { Name = "e2e-caseType" }, x => x.Code, useAlphaNumeric: true);
            var propertyType = InsertWithNewId(new PropertyType { Name = "e2e-propertyType" }, x => x.Code, useAlphaNumeric: true);
            var jurisdiction = InsertWithNewId(new Country { Name = "e2e-country", Type = "1" }, x => x.Id, useAlphaNumeric: true);
            var caseCategory = InsertWithNewId(new CaseCategory { Name = "e2e-caseCategory", CaseType = caseType }, x => x.CaseCategoryId, useAlphaNumeric: true, maxLength: 2);
            var subType = InsertWithNewId(new SubType { Name = "e2e-subType" }, x => x.Code, useAlphaNumeric: true);
            var c1 = new CurrencyBuilder(DbContext).Create(Fixture.String(3));
            var c2 = new CurrencyBuilder(DbContext).Create(Fixture.String(3));
            var ex1 = DbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().Add(new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = "AAA" + Fixture.String(3), Description = Fixture.String(10)});
            DbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().Add(new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = "BBB" + Fixture.String(3), Description = Fixture.String(10)});
            if (!DbContext.Set<ValidProperty>().Any(_ => _.PropertyName == ValidPropertyTypeDescription))
            {
                DbContext.Set<ValidProperty>().Add(new ValidProperty
                {
                    CountryId = jurisdiction.Id,
                    PropertyTypeId = propertyType.Code,
                    PropertyName = ValidPropertyTypeDescription
                });
            }

            if (!DbContext.Set<ValidCategory>().Any(_ => _.CaseCategoryDesc == ValidCaseCategoryDescription))
            {
                DbContext.Set<ValidCategory>().Add(new ValidCategory
                {
                    CountryId = jurisdiction.Id,
                    PropertyTypeId = propertyType.Code,
                    CaseTypeId = caseType.Code,
                    CaseCategoryId = caseCategory.CaseCategoryId,
                    CaseCategoryDesc = ValidCaseCategoryDescription
                });
            }

            if (!DbContext.Set<ValidSubType>().Any(_ => _.SubTypeDescription == ValidSubTypeDescription))
            {
                DbContext.Set<ValidSubType>().Add(new ValidSubType
                {
                    CountryId = jurisdiction.Id,
                    PropertyTypeId = propertyType.Code,
                    CaseTypeId = caseType.Code,
                    CaseCategoryId = caseCategory.CaseCategoryId,
                    SubtypeId = subType.Code,
                    SubTypeDescription = ValidSubTypeDescription
                });
            }

            var e1 = Insert(new ExchangeRateVariation {Currency = c1, CaseType = caseType, Country = jurisdiction, PropertyTypeCode = propertyType.Code, CaseCategoryCode = caseCategory.CaseCategoryId, SubtypeCode = subType.Code, EffectiveDate = Fixture.PastDate(), BuyRate = Convert.ToDecimal(1.03), SellRate = Convert.ToDecimal(1.20)});
            var e2 = Insert(new ExchangeRateVariation {Currency = c1, CaseType = caseType, Country = jurisdiction, EffectiveDate = Fixture.PastDate(), BuyRate = Convert.ToDecimal(1.12), SellRate = Convert.ToDecimal(1.45)});
            var e3 = Insert(new ExchangeRateVariation {ExchangeRateSchedule = ex1, CaseType = caseType, Country = jurisdiction, EffectiveDate = Fixture.PastDate(), BuyRate = Convert.ToDecimal(1.12), SellRate = Convert.ToDecimal(1.45)});
            return new
            {
                e1,
                e2,
                e3
            };
        }
    }
}
