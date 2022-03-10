using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Persistence;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using static Inprotech.Web.Picklists.ExchangeRateSchedulePicklistController;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Web.Configuration.ExchangeRateSchedule
{
    public interface IExchangeRateScheduleService
    {
        Task<IEnumerable<ExchangeRateSchedulePicklistItem>> GetExchangeRateSchedule();
        Task<ValidationError> ValidateExistingCode(string code);
        Task<ExchangeRateSchedulePicklistItem> GetExchangeRateScheduleDetails(int id);
        Task<string> SubmitExchangeRateSchedule(ExchangeRateSchedulePicklistItem model);
        Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel);
    }

    public class ExchangeRateScheduleService : IExchangeRateScheduleService
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public ExchangeRateScheduleService(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public async Task<IEnumerable<ExchangeRateSchedulePicklistItem>> GetExchangeRateSchedule()
        {
            var culture = _preferredCultureResolver.Resolve();
            return await (from ers in _dbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>()
                          select new ExchangeRateSchedulePicklistItem
                          {
                              Id = ers.Id,
                              Code = ers.ExchangeScheduleCode,
                              Description = DbFuncs.GetTranslation(ers.Description, null, ers.DescriptionTId, culture) ?? string.Empty
                          }).ToListAsync();
        }

        public async Task<ValidationError> ValidateExistingCode(string code)
        {
            var allCodes = await _dbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().ToListAsync();

            if (allCodes.Any(_ => string.Equals(_.ExchangeScheduleCode, code, StringComparison.CurrentCultureIgnoreCase)))
            {
                return ValidationErrors.SetCustomError("code",
                                                       "field.errors.duplicateExchangeRateScheduleCode", null, true);
            }

            return null;
        }

        public async Task<ExchangeRateSchedulePicklistItem> GetExchangeRateScheduleDetails(int id)
        {
            var culture = _preferredCultureResolver.Resolve();
            var result = await _dbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>()
                                         .Where(x => x.Id == id)
                                         .Select(x => new ExchangeRateSchedulePicklistItem
                                         {
                                             Id = x.Id,
                                             Code = x.ExchangeScheduleCode,
                                             Description = DbFuncs.GetTranslation(x.Description, null, x.DescriptionTId, culture)
                                         }).FirstOrDefaultAsync();

            if (result == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return result;
        }

        public async Task<string> SubmitExchangeRateSchedule(ExchangeRateSchedulePicklistItem model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var exchangeRateSchedule = await _dbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().FirstOrDefaultAsync(x => x.Id == model.Id);
            if (exchangeRateSchedule != null)
            {
                exchangeRateSchedule.Description = model.Description;
            }
            else
            {
                exchangeRateSchedule = new InprotechKaizen.Model.Names.ExchangeRateSchedule
                {
                    ExchangeScheduleCode = model.Code,
                    Description = model.Description
                };
                _dbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().Add(exchangeRateSchedule);
            }

            await _dbContext.SaveChangesAsync();
            return model.Code;
        }

        public async Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null || !deleteRequestModel.Ids.Any()) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            var exchangeRateSchedules = _dbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

            using (var txScope = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                foreach (var ex in exchangeRateSchedules)
                {
                    try
                    {
                        _dbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().Remove(ex);
                        await _dbContext.SaveChangesAsync();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int) SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(ex.Id);
                        }
                        _dbContext.Detach(ex);
                    }
                }
                txScope.Complete();
            }

            if (!response.InUseIds.Any()) return response;
            response.HasError = true;
            response.Message = ConfigurationResources.InUseErrorMessage;

            return response;
        }
    }
}