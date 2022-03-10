using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.TaxCode
{
    public interface ITaxCodeMaintenanceService
    {
        Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel);
        Task<dynamic> CreateTaxCode(TaxCodes taxCodes);
        Task<DeleteResponseModel> MaintainTaxCodeDetails(TaxCodeSaveDetails taxCodeSaveDetails);
    }

    public class TaxCodeMaintenanceService : ITaxCodeMaintenanceService
    {
        readonly IDbContext _dbContext;
        readonly ITaxCodesValidator _taxCodesValidator;

        public TaxCodeMaintenanceService(IDbContext dbContext, ITaxCodesValidator taxCodesValidator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _taxCodesValidator = taxCodesValidator;
        }

        public async Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();
            var taxCode = _dbContext.Set<TaxRate>().Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();
            if (!taxCode.Any()) throw new InvalidDataException(nameof(taxCode));
            using (var txScope = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                response.InUseIds = new List<int>();
                foreach (var r in taxCode)
                {
                    try
                    {
                        _dbContext.Set<TaxRate>().Remove(r);
                        await _dbContext.SaveChangesAsync();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(r.Id);
                        }

                        _dbContext.Detach(r);
                    }
                }

                txScope.Complete();
                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                    return response;
                }
            }

            return response;
        }

        public async Task<dynamic> CreateTaxCode(TaxCodes taxCodes)
        {
            if (taxCodes == null)
            {
                throw new ArgumentNullException(nameof(taxCodes));
            }

            var validationErrors = _taxCodesValidator.Validate(taxCodes.TaxCode, Operation.Add).ToArray();
            if (validationErrors.Any())
            {
                return validationErrors.AsErrorResponse();
            }

            var taxRate = new TaxRate
            {
                Code = taxCodes.TaxCode,
                Description = taxCodes.Description
            };

            _dbContext.Set<TaxRate>().Add(taxRate);

            await _dbContext.SaveChangesAsync();

            return new
            {
                Result = "success",
                TaxRateId = taxRate.Id
            };
        }

        public async Task<DeleteResponseModel> MaintainTaxCodeDetails(TaxCodeSaveDetails taxCodeSaveDetails)
        {
            if (taxCodeSaveDetails.OverviewDetails == null)
            {
                throw new ArgumentNullException(nameof(taxCodeSaveDetails));
            }

            var response = new DeleteResponseModel();
            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var taxCode = _dbContext.Set<TaxRate>().Single(_ => _.Id == taxCodeSaveDetails.OverviewDetails.Id);
                taxCode.Description = taxCodeSaveDetails.OverviewDetails.Description;

                if (taxCodeSaveDetails.TaxRatesDetails != null)
                {
                    var taxRatesToAdd = taxCodeSaveDetails.TaxRatesDetails.Where(_ => _.Status == InlineEditingStates.Added).ToArray();
                    var taxRatesToUpdate = taxCodeSaveDetails.TaxRatesDetails.Where(_ => _.Status == InlineEditingStates.Modified).ToArray();
                    var taxRatesToDelete = taxCodeSaveDetails.TaxRatesDetails.Where(_ => _.Status == InlineEditingStates.Deleted).Select(_ => _.Id);
                    var ratesToDelete = taxRatesToDelete as int[] ?? taxRatesToDelete.ToArray();

                    if (ratesToDelete.Any())
                    {
                        DeleteTaxRates(ratesToDelete);
                    }

                    if (taxRatesToAdd.Any())
                    {
                        InsertTaxRates(taxRatesToAdd, taxCodeSaveDetails.OverviewDetails.TaxCode);
                    }

                    if (taxRatesToUpdate.Any())
                    {
                        UpdateTaxRates(taxRatesToUpdate);
                    }
                }

                await _dbContext.SaveChangesAsync();
                t.Complete();
                response.Message = "success";
            }

            return response;
        }

        void UpdateTaxRates(IEnumerable<TaxRates> taxRates)
        {
            foreach (var taxRate in taxRates)
            {
                var taxRateToUpdate = _dbContext.Set<TaxRatesCountry>()
                                                .Single(_ => _.TaxRateCountryId == taxRate.Id);
                taxRateToUpdate.EffectiveDate = taxRate.EffectiveDate;
                taxRateToUpdate.Rate = Convert.ToDecimal(taxRate.TaxRate);
                taxRateToUpdate.CountryId = taxRate.SourceJurisdiction.Key == string.Empty ? KnownValues.DefaultCountryCode : taxRate.SourceJurisdiction.Key;
            }
        }

        void InsertTaxRates(IEnumerable<TaxRates> taxRates, string taxCode)
        {
            foreach (var taxRate in taxRates)
            {
                _dbContext.Set<TaxRatesCountry>().Add(new TaxRatesCountry
                {
                    CountryId = taxRate.SourceJurisdiction == null ? KnownValues.DefaultCountryCode : taxRate.SourceJurisdiction.Code,
                    TaxCode = taxCode,
                    EffectiveDate = taxRate.EffectiveDate,
                    Rate = Convert.ToDecimal(taxRate.TaxRate)
                });
            }
        }

        void DeleteTaxRates(IEnumerable<int> taxRateIds)
        {
            var taxRatesCountries = _dbContext.Set<TaxRatesCountry>().Where(_ => taxRateIds.Contains(_.TaxRateCountryId)).ToArray();
            foreach (var taxRate in taxRatesCountries) _dbContext.Set<TaxRatesCountry>().Remove(taxRate);
        }
    }

    public class DeleteResponseModel
    {
        public List<int> InUseIds { get; set; }
        public bool HasError { get; set; }
        public string Message { get; set; }
    }

    public class DeleteRequestModel
    {
        public List<int> Ids { get; set; }
    }

    public class TaxCodeDetails
    {
        public IEnumerable<TaxCodes> TaxCodes { get; set; }
        public IEnumerable<int> Ids { get; set; }
    }

    public class TaxCodeSaveDetails
    {
        public TaxCodes OverviewDetails { get; set; }
        public List<TaxRates> TaxRatesDetails { get; set; }
    }

    public class TaxRates
    {
        public SourceJurisdiction SourceJurisdiction { get; set; }
        public string TaxRate { get; set; }
        public DateTime? EffectiveDate { get; set; }
        public int Id { get; set; }
        public string Status { get; set; }
    }

    public static class InlineEditingStates
    {
        public const string Added = "A";
        public const string Modified = "M";
        public const string Deleted = "D";
    }
}