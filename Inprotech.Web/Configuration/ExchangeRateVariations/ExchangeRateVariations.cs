using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Web.Configuration.ExchangeRateVariations
{
    public interface IExchangeRateVariations
    {
        IEnumerable<ExchangeRateVariationsResult> GetExchangeRateVariations(ExchangeRateVariationsFilterModel filter);
        Task<ExchangeRateVariationModel> GetExchangeRateVariationDetails(int id);
        Task<dynamic> SubmitExchangeRateVariation(ExchangeRateVariationRequest model);
        Task<ValidationError> ValidateDuplicateExchangeVariation(ExchangeRateVariationRequest request);
        Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel);
    }

    public class ExchangeRateVariations : IExchangeRateVariations
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public ExchangeRateVariations(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<ExchangeRateVariationsResult> GetExchangeRateVariations(ExchangeRateVariationsFilterModel filter)
        {
            if (filter == null) throw new ArgumentNullException("filter");

            var exchangeRateVariations = _dbContext.Set<ExchangeRateVariation>().AsQueryable();
            if (filter.IsExactMatch)
            {
                exchangeRateVariations = exchangeRateVariations.Where(_ => (_.ExchScheduleId == filter.ExchangeRateScheduleId || filter.ExchangeRateScheduleId == null)
                                                                           && (_.CurrencyCode == filter.CurrencyCode || filter.CurrencyCode == null)
                                                                           && (_.CaseTypeCode == filter.CaseType || filter.CaseType == null)
                                                                           && (_.CountryCode == filter.CountryCode || filter.CountryCode == null)
                                                                           && (_.PropertyTypeCode == filter.PropertyType || filter.PropertyType == null)
                                                                           && (_.CaseCategoryCode == filter.CaseCategory || filter.CaseCategory == null)
                                                                           && (_.SubtypeCode == filter.SubType || filter.SubType == null));
            }
            else
            {
                exchangeRateVariations = exchangeRateVariations.Where(_ => (_.ExchScheduleId == filter.ExchangeRateScheduleId || _.ExchScheduleId == null)
                                                                           && (_.CurrencyCode == filter.CurrencyCode || _.CurrencyCode == null)
                                                                           && (_.CaseTypeCode == filter.CaseType || _.CountryCode == null)
                                                                           && (_.CountryCode == filter.CountryCode || filter.CountryCode == null)
                                                                           && (_.PropertyTypeCode == filter.PropertyType || _.PropertyTypeCode == null)
                                                                           && (_.CaseCategoryCode == filter.CaseCategory || _.CaseCategoryCode == null)
                                                                           && (_.SubtypeCode == filter.SubType || _.SubtypeCode == null));
            }

            return GetVariations(exchangeRateVariations).OrderBy(_ => _.Currency).ThenBy(_ => _.ExchangeRateSchedule).DistinctBy(_ => _.Id);
        }

        IQueryable<ExchangeRateVariationsResult> GetVariations(IQueryable<ExchangeRateVariation> exchangeRateVariations)
        {
            var culture = _preferredCultureResolver.Resolve();
            var validProperty = _dbContext.Set<ValidProperty>();
            var validCategory = _dbContext.Set<ValidCategory>();
            var validSubType = _dbContext.Set<ValidSubType>();

            return from e in exchangeRateVariations
                   join vp in _dbContext.Set<ValidProperty>() on new
                   {
                       PropertyTypeId = e.PropertyTypeCode,
                       CountryId = validProperty
                                       .Where(_ => _.PropertyTypeId == e.PropertyTypeCode && new[] { e.CountryCode, KnownValues.DefaultCountryCode }.Contains(_.CountryId))
                                       .Select(_ => _.CountryId)
                                       .Min()
                   }
                       equals new { vp.PropertyTypeId, vp.CountryId } into vp1
                   from vp in vp1.DefaultIfEmpty()
                   join p in _dbContext.Set<PropertyType>() on e.PropertyTypeCode equals p.Code into p1
                   from p in p1.DefaultIfEmpty()
                   join vc in _dbContext.Set<ValidCategory>() on new
                   {
                       PropertyTypeId = e.PropertyTypeCode,
                       CaseTypeId = e.CaseTypeCode,
                       CaseCategoryId = e.CaseCategoryCode,
                       CountryId = validCategory
                                       .Where(_ => _.PropertyTypeId == e.PropertyTypeCode && _.CaseTypeId == e.CaseTypeCode
                                                                                          && _.CaseCategoryId == e.CaseCategoryCode
                                                                                          && new[] { e.CountryCode, KnownValues.DefaultCountryCode }.Contains(_.CountryId))
                                       .Select(_ => _.CountryId)
                                       .Min()
                   }
                       equals new { vc.PropertyTypeId, vc.CaseTypeId, vc.CaseCategoryId, vc.CountryId } into vc1
                   from vc in vc1.DefaultIfEmpty()
                   join c in _dbContext.Set<CaseCategory>() on e.CaseCategoryCode equals c.CaseCategoryId into c1
                   from c in c1.DefaultIfEmpty()
                   join vst in _dbContext.Set<ValidSubType>() on new
                   {
                       PropertyTypeId = e.PropertyTypeCode,
                       CaseTypeId = e.CaseTypeCode,
                       CaseCategoryId = e.CaseCategoryCode,
                       SubtypeId = e.SubtypeCode,
                       CountryId = validSubType
                                       .Where(_ => _.PropertyTypeId == e.PropertyTypeCode && _.CaseTypeId == e.CaseTypeCode
                                                                                          && _.CaseCategoryId == e.CaseCategoryCode
                                                                                          && _.SubtypeId == e.SubtypeCode
                                                                                          && new[] { e.CountryCode, KnownValues.DefaultCountryCode }.Contains(_.CountryId))
                                       .Select(_ => _.CountryId)
                                       .Min()
                   }
                       equals new { vst.PropertyTypeId, vst.CaseTypeId, vst.CaseCategoryId, vst.SubtypeId, vst.CountryId } into vst1
                   from vst in vst1.DefaultIfEmpty()
                   join s in _dbContext.Set<SubType>() on e.SubtypeCode equals s.Code into s1
                   from s in s1.DefaultIfEmpty()
                   select new ExchangeRateVariationsResult
                   {
                       Id = e.Id,
                       ExchangeRateScheduleId = e.ExchScheduleId,
                       ExchangeRateSchedule = e.ExchScheduleId != null ? DbFuncs.GetTranslation(e.ExchangeRateSchedule.Description, null, e.ExchangeRateSchedule.DescriptionTId, culture) : null,
                       CurrencyCode = e.CurrencyCode,
                       Currency = e.Currency != null ? DbFuncs.GetTranslation(e.Currency.Description, null, e.Currency.DescriptionTId, culture) : string.Empty,
                       CaseTypeCode = e.CaseTypeCode,
                       CaseTypeId = e.CaseType != null ? e.CaseType.Id : (int?)null,
                       CaseType = e.CaseType != null ? DbFuncs.GetTranslation(e.CaseType.Name, null, e.CaseType.NameTId, culture) : string.Empty,
                       CountryCode = e.CountryCode,
                       Country = e.Country != null ? DbFuncs.GetTranslation(e.Country.Name, null, e.Country.NameTId, culture) : string.Empty,
                       PropertyTypeCode = e.PropertyTypeCode,
                       PropertyType = vp != null ? DbFuncs.GetTranslation(vp.PropertyName, null, vp.PropertyNameTId, culture) : p != null ?
                           DbFuncs.GetTranslation(p.Name, null, p.NameTId, culture) : string.Empty,
                       CaseCategoryCode = e.CaseCategoryCode,
                       CaseCategory = vc != null ? DbFuncs.GetTranslation(vc.CaseCategoryDesc, null, vc.CaseCategoryDescTid, culture) : c != null ?
                           DbFuncs.GetTranslation(c.Name, null, c.NameTId, culture) : string.Empty,
                       SubTypeCode = e.SubtypeCode,
                       SubType = vst != null ? DbFuncs.GetTranslation(vst.SubTypeDescription, null, vst.SubTypeDescriptionTid, culture) : s != null ?
                           DbFuncs.GetTranslation(s.Name, null, s.NameTId, culture) : string.Empty,
                       EffectiveDate = e.EffectiveDate,
                       BuyFactor = e.BuyFactor,
                       SellFactor = e.SellFactor,
                       BuyRate = e.BuyRate,
                       SellRate = e.SellRate,
                       Notes = e.Notes
                   };
        }

        public async Task<ExchangeRateVariationModel> GetExchangeRateVariationDetails(int id)
        {
            var exchangeRateVariations = _dbContext.Set<ExchangeRateVariation>().Where(x => x.Id == id);

            var data = await GetVariations(exchangeRateVariations).FirstOrDefaultAsync();

            if (data == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return new ExchangeRateVariationModel
            {
                Id = data.Id,
                Currency = data.Currency != null ? new PicklistItem { Code = data.CurrencyCode, Value = data.Currency } : null,
                ExchRateSch = data.ExchangeRateScheduleId != null ? new PicklistItem { Id = data.ExchangeRateScheduleId, Value = data.ExchangeRateSchedule } : null,
                CaseType = data.CaseTypeCode != null ? new PicklistItem { Key = data.CaseTypeId, Code = data.CaseTypeCode, Value = data.CaseType } : null,
                CaseCategory = data.CaseCategoryCode != null ? new PicklistItem { Code = data.CaseCategoryCode, Value = data.CaseCategory } : null,
                PropertyType = data.PropertyTypeCode != null ? new PicklistItem { Code = data.PropertyTypeCode, Value = data.PropertyType } : null,
                Country = data.CountryCode != null ? new PicklistItem { Code = data.CountryCode, Value = data.Country } : null,
                SubType = data.SubTypeCode != null ? new PicklistItem { Code = data.SubTypeCode, Value = data.SubType } : null,
                SellFactor = data.SellFactor,
                SellRate = data.SellRate,
                BuyRate = data.BuyRate,
                BuyFactor = data.BuyFactor,
                EffectiveDate = data.EffectiveDate ?? DateTime.Now,
                Notes = data.Notes
            };
        }

        public async Task<ValidationError> ValidateDuplicateExchangeVariation(ExchangeRateVariationRequest request)
        {

            if (request == null) throw new ArgumentNullException(nameof(request));

            var allRecords = await _dbContext.Set<ExchangeRateVariation>().ToListAsync();
            var sameCurrencyRecords = allRecords.Where(_ => (_.CurrencyCode == request.CurrencyCode || (_.CurrencyCode == null && request.CurrencyCode == null))
                                                            && (_.ExchScheduleId == request.ExchScheduleId || (_.ExchScheduleId == null && request.ExchScheduleId == null))
                                                            && (_.CountryCode == request.CountryCode || (_.CountryCode == null && request.CountryCode == null))
                                                            && (_.CaseCategoryCode == request.CaseCategoryCode || (_.CaseCategoryCode == null && request.CaseCategoryCode == null))
                                                            && (_.CaseTypeCode == request.CaseTypeCode || (_.CaseTypeCode == null && request.CaseTypeCode == null))
                                                            && (_.PropertyTypeCode == request.PropertyTypeCode || (_.PropertyTypeCode == null && request.PropertyTypeCode == null))
                                                            && (_.SubtypeCode == request.SubTypeCode || (_.SubtypeCode == null && request.SubTypeCode == null))).ToArray();

            if (request.Id > 0)
            {
                sameCurrencyRecords = sameCurrencyRecords.Where(x => x.Id != request.Id).ToArray();
            }
            if (sameCurrencyRecords.Length > 0)
            {
                return ValidationErrors.SetCustomError("currencyCode",
                                                       "field.errors.duplicateExchangeRateVariation", null, true);
            }

            return null;
        }

        public async Task<dynamic> SubmitExchangeRateVariation(ExchangeRateVariationRequest model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var exRate = await _dbContext.Set<ExchangeRateVariation>().FirstOrDefaultAsync(x => x.Id == model.Id);
            if (exRate != null)
            {
                var response = await ValidateDuplicateExchangeVariation(model);
                if (response != null)
                {
                    return response;
                }
                exRate.CurrencyCode = model.CurrencyCode;
                exRate.ExchScheduleId = model.ExchScheduleId;
            }
            else
            {
                exRate = new ExchangeRateVariation
                {
                    CurrencyCode = model.CurrencyCode,
                    ExchScheduleId = model.ExchScheduleId,
                };
                _dbContext.Set<ExchangeRateVariation>().Add(exRate);
            }
            exRate.CaseTypeCode = model.CaseTypeCode;
            exRate.CountryCode = model.CountryCode;
            exRate.CaseCategoryCode = model.CaseCategoryCode;
            exRate.PropertyTypeCode = model.PropertyTypeCode;
            exRate.SubtypeCode = model.SubTypeCode;
            exRate.BuyFactor = model.BuyFactor;
            exRate.BuyRate = model.BuyRate;
            exRate.SellRate = model.SellRate;
            exRate.SellFactor = model.SellFactor;
            exRate.EffectiveDate = model.EffectiveDate;
            exRate.Notes = model.Notes;

            await _dbContext.SaveChangesAsync();
            return exRate.Id;
        }

        public async Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null || !deleteRequestModel.Ids.Any()) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();
            var exchangeExchangeRateVariations = _dbContext.Set<ExchangeRateVariation>().Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();
            using var txScope = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);
            foreach (var exv in exchangeExchangeRateVariations)
            {
                try
                {
                    _dbContext.Set<ExchangeRateVariation>().Remove(exv);
                    await _dbContext.SaveChangesAsync();
                }
                catch (Exception e)
                {
                    var sqlException = e.FindInnerException<SqlException>();
                    if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                    {
                        response.InUseIds.Add(exv.Id);
                    }
                    _dbContext.Detach(exv);
                }
            }
            txScope.Complete();

            if (!response.InUseIds.Any()) return response;
            response.HasError = true;
            response.Message = ConfigurationResources.InUseErrorMessage;
            return response;
        }
    }
}
