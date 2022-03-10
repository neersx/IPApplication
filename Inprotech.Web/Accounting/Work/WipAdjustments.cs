using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Infrastructure.Policy;
using Inprotech.Web.Extentions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Core;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using TransactionStatus = InprotechKaizen.Model.Accounting.TransactionStatus;

namespace Inprotech.Web.Accounting.Work
{
    public interface IWipAdjustments
    {
        Task<object> GetReasons(string culture);

        Task<dynamic> GetWipDefaults(int? caseKey, string activityKey);

        Task<bool> CaseHasMultipleDebtors(int? caseId);

        Task<ValidationErrorCollection> ValidateItemDate(DateTime date);

        Task<dynamic> GetItemToAdjust(int userIdentityId, string culture, int entityKey, int transKey, int wipSeqKey);

        Task AdjustItems(int userIdentityId, string culture, ChangeSetEntry<AdjustWipItemDto>[] adjustItemChangeSet);

        Task<object> GetItemToSplit(int userIdentityId, string culture, int entityKey, int transKey, int wipSeqKey);

        Task SplitItems(int userIdentityId, string culture, ChangeSetEntry<SplitWipItem>[] splitItemChangeSet);
        Task<dynamic> GetStaffProfitCenter(int nameKey, string culture);
    }

    public class WipAdjustments : IWipAdjustments
    {
        readonly IAdjustWipCommand _adjustWipCommand;
        readonly IApplicationAlerts _applicationAlerts;
        readonly ICurrentNames _currentNames;
        readonly Func<DateTime> _today;
        readonly IDbContext _dbContext;
        readonly IGetWipItemCommand _getWipItemCommand;

        readonly ILogger<WipAdjustments> _logger;
        readonly ISiteDateFormat _siteDateFormat;
        readonly ISplitWipCommand _splitWipCommand;

        readonly IValidatePostDates _validatePostDates;
        readonly IWipDefaulting _wipDefaulting;

        public WipAdjustments(IDbContext dbContext,
                              ILogger<WipAdjustments> logger,
                              IValidatePostDates validatePostDates,
                              ISiteDateFormat siteDateFormat,
                              IGetWipItemCommand getWipItemCommand,
                              IWipDefaulting wipDefaulting,
                              IAdjustWipCommand adjustWipCommand,
                              ISplitWipCommand splitWipCommand,
                              IApplicationAlerts applicationAlerts,
                              ICurrentNames currentNames,
                              Func<DateTime> today)
        {
            _validatePostDates = validatePostDates;
            _siteDateFormat = siteDateFormat;
            _getWipItemCommand = getWipItemCommand;
            _wipDefaulting = wipDefaulting;
            _adjustWipCommand = adjustWipCommand;
            _splitWipCommand = splitWipCommand;
            _applicationAlerts = applicationAlerts;
            _dbContext = dbContext;
            _logger = logger;
            _currentNames = currentNames;
            _today = today;
        }

        static string[] AdjustWipPrimaryKeys => new[] { "EntityKey", "TransKey", "WIPSeqKey" };

        static string[] SplitWipPrimaryKeys => new[] { "EntityKey", "NewTransKey", "NewWipSeqKey" };

        public async Task AdjustItems(int userIdentityId, string culture, ChangeSetEntry<AdjustWipItemDto>[] adjustItemChangeSet)
        {
            if (adjustItemChangeSet == null) throw new ArgumentNullException(nameof(adjustItemChangeSet));

            await SaveChanges(adjustItemChangeSet,
                              async changeSetEntry =>
                              {
                                  var result = await _adjustWipCommand.SaveAdjustment(userIdentityId, culture, changeSetEntry, false);
                                  if (result.NewTransKey != null)
                                  {
                                      changeSetEntry.NewTransKey = result.NewTransKey;
                                      if (result.NewTransKey != null && changeSetEntry.AdjustDiscount)
                                      {
                                          var discountedWipItem = await GetDiscountItem(
                                                                                        changeSetEntry.EntityKey,
                                                                                        changeSetEntry.TransKey,
                                                                                        changeSetEntry.WipSeqNo,
                                                                                        changeSetEntry);

                                          if (discountedWipItem != null)
                                          {
                                              await _adjustWipCommand.SaveAdjustment(userIdentityId, culture, discountedWipItem, false);
                                          }
                                      }
                                  }
                              },
                              changeSetEntry => changeSetEntry.TransDate,
                              AdjustWipPrimaryKeys);
        }

        public async Task SplitItems(int userIdentityId, string culture, ChangeSetEntry<SplitWipItem>[] splitItemChangeSet)
        {
            if (splitItemChangeSet == null) throw new ArgumentNullException(nameof(splitItemChangeSet));

            int? newTransKey = null;

            var last = splitItemChangeSet.Last().Entity;

            await SaveChanges(splitItemChangeSet,
                              async changeSetEntry =>
                              {
                                  changeSetEntry.NewTransKey = newTransKey;
                                  changeSetEntry.IsLastSplit = changeSetEntry == last;
                                  if (changeSetEntry.IsCreditWip)
                                  {
                                      changeSetEntry.LocalAmount *= -1;
                                      changeSetEntry.ForeignAmount *= -1;
                                  }

                                  var result = await _splitWipCommand.Split(userIdentityId, culture, changeSetEntry);
                                  if (result.NewTransKey != null)
                                  {
                                      newTransKey = result.NewTransKey;
                                      changeSetEntry.NewTransKey = result.NewTransKey;
                                      changeSetEntry.NewWipSeqKey = result.NewWipSeqKey;
                                  }
                              },
                              changeSetEntry => changeSetEntry.TransDate,
                              SplitWipPrimaryKeys);
        }

        public async Task<dynamic> GetStaffProfitCenter(int nameKey, string culture)
        {
            return await (from e in _dbContext.Set<Employee>().Where(_ => _.Id == nameKey)
                          join p in _dbContext.Set<ProfitCentre>() on e.ProfitCentre equals p.Id
                          select new
                          {
                              Code = p.Id,
                              Description = DbFuncs.GetTranslation(p.Name, null, p.NameTId, culture)
                          }).FirstOrDefaultAsync();
        }

        public async Task<dynamic> GetWipDefaults(int? caseKey, string activityKey)
        {
            var wipTemplateFilter = new WipTemplateFilterCriteria
            {
                ContextCriteria = { CaseKey = caseKey },
                WipCategory = { IsDisbursements = true, IsOverheads = true, IsServices = true },
                UsedByApplication = { IsWip = true }
            };

            return await _wipDefaulting.ForActivity(wipTemplateFilter, caseKey, activityKey);
        }

        public async Task<ValidationErrorCollection> ValidateItemDate(DateTime date)
        {
            var result = await _validatePostDates.For(date);
            if (result.isValid)
            {
                return new ValidationErrorCollection();
            }

            return new ValidationErrorCollection
            {
                ValidationErrorList = new List<ValidationError>
                {
                    new()
                    {
                        WarningCode = result.isWarningOnly ? result.code : string.Empty,
                        WarningDescription = result.isWarningOnly ? KnownErrors.CodeMap[result.code] : string.Empty,
                        ErrorCode = !result.isWarningOnly ? result.code : string.Empty,
                        ErrorDescription = !result.isWarningOnly ? KnownErrors.CodeMap[result.code] : string.Empty
                    }
                }
            };
        }

        public async Task<bool> CaseHasMultipleDebtors(int? caseId)
        {
            if (caseId == null) return false;

            var currentDebtors = _currentNames.For((int)caseId, KnownNameTypes.Debtor);

            return await currentDebtors.CountAsync() > 1;
        }

        public async Task<dynamic> GetReasons(string culture)
        {
            return await (from r in _dbContext.Set<Reason>()
                          where r.UsedBy != null && ((int)r.UsedBy & (int)KnownApplicationUsage.Wip) == (int)KnownApplicationUsage.Wip
                          select new
                          {
                              ReasonKey = r.Code,
                              ReasonDescription = DbFuncs.GetTranslation(r.Description, null, r.DescriptionTId, culture),
                              ShowOnDebitNote = r.ShowOnDebitNote == 1
                          }).ToArrayAsync();
        }

        public async Task<dynamic> GetItemToSplit(int userIdentityId, string culture, int entityKey, int transKey, int wipSeqKey)
        {
            try
            {
                var originalWipItem = await _getWipItemCommand.GetWipItem(userIdentityId, culture, entityKey, transKey, wipSeqKey);

                if (originalWipItem.Balance < 0)
                {
                    originalWipItem.IsCreditWip = true;
                    originalWipItem.LocalValue = originalWipItem.LocalValue * -1;
                    originalWipItem.Balance = originalWipItem.Balance * -1;
                    originalWipItem.ForeignValue = originalWipItem.ForeignValue * -1;
                    originalWipItem.ForeignBalance = originalWipItem.ForeignBalance * -1;
                }

                originalWipItem.DateStyle = _siteDateFormat.Resolve(culture);

                return originalWipItem;
            }
            catch (Exception e)
            {
                var sqlException = e.FindInnerException<SqlException>();
                if (sqlException != null)
                {
                    if (_applicationAlerts.TryParse(sqlException.Message, out var alerts))
                    {
                        return new
                        {
                            EntityKey = entityKey,
                            TransKey = transKey,
                            WipSeqKey = wipSeqKey,
                            Alerts = alerts.Select(_ => _.Message).ToArray()
                        };
                    }
                }

                throw;
            }
        }

        public async Task<dynamic> GetItemToAdjust(int userIdentityId, string culture, int entityKey, int transKey, int wipSeqKey)
        {
            try
            {
                var originalWipItem = await _getWipItemCommand.GetWipItem(userIdentityId, culture, entityKey, transKey, wipSeqKey);

                var dateStyle = _siteDateFormat.Resolve(culture);

                var isDiscountAvailable = await IsWipAvailableForDiscountTransfer(entityKey, transKey, wipSeqKey) &&
                                          await GetDiscountItem(entityKey, transKey, wipSeqKey) != null;

                return new
                {
                    AdjustWipItem = new
                    {
                        OriginalWIPItem = originalWipItem,
                        TransDate = new DateTime(_today().Date.Ticks, DateTimeKind.Unspecified),
                        originalWipItem.EntityKey,
                        originalWipItem.TransKey,
                        originalWipItem.WIPSeqKey,
                        originalWipItem.LogDateTimeStamp,
                        AdjustmentType = TransactionType.DebitWipAdjustment,
                        originalWipItem.RequestedByStaffKey,
                        originalWipItem.RequestedByStaffCode,
                        originalWipItem.RequestedByStaffName,
                        NewNarrativeKey = originalWipItem.NarrativeKey,
                        NewNarrativeCode = originalWipItem.NarrativeCode,
                        NewNarrativeTitle = originalWipItem.NarrativeTitle,
                        NewDebitNoteText = originalWipItem.DebitNoteText,
                        DateStyle = dateStyle,
                        IsDiscountItemAvailable = isDiscountAvailable
                    }
                };
            }
            catch (Exception e)
            {
                var sqlException = e.FindInnerException<SqlException>();
                if (sqlException != null)
                {
                    if (_applicationAlerts.TryParse(sqlException.Message, out var alerts))
                    {
                        return new
                        {
                            Alerts = alerts.Select(_ => _.Message).ToArray()
                        };
                    }
                }

                throw;
            }
        }

        async Task SaveChanges<T>(ChangeSetEntry<T>[] changeSet, Func<T, Task> changeSetEntryPersistor, Func<T, DateTime> validator, string[] keys)
        {
            using var tsc = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);

            var index = 0;

            foreach (var changeSetEntry in changeSet)
            {
                var transactionDate = validator(changeSetEntry.Entity);
                var validateResult = await ValidateItemDate(transactionDate);
                if (validateResult.HasError && !(string.IsNullOrWhiteSpace(validateResult.FirstErrorDescription) && changeSetEntry.IsItemDateWarningSuppressed))
                {
                    changeSetEntry.ValidationErrors = new List<ValidationResultInfo>
                    {
                    new($"{validateResult.FirstErrorDescription}", 0, string.Empty, keys)
                    };
                    break;
                }

                try
                {
                    _logger.Debug($"Persisting {typeof(T).Name} #{index}", changeSetEntry.Entity);

                    await changeSetEntryPersistor(changeSetEntry.Entity);

                    _logger.Debug($"Persisted {typeof(T).Name} #{index}", changeSetEntry.Entity);
                }
                catch (Exception e)
                {
                    var sqlException = e.FindInnerException<SqlException>();
                    if (sqlException != null)
                    {
                        if (_applicationAlerts.TryParse(sqlException.Message, out var alerts))
                        {
                            changeSetEntry.ValidationErrors = alerts.Select(a => new ValidationResultInfo(a.Message, keys));
                            break;
                        }

                        _logger.Exception(e);
                        changeSetEntry.ValidationErrors = new List<ValidationResultInfo>
                        {
                            new(sqlException.Message, 0, sqlException.StackTrace, keys)
                        };
                        break;
                    }

                    _logger.Exception(e);
                    changeSetEntry.ValidationErrors = new List<ValidationResultInfo>
                    {
                        new(e.Message, 0, e.StackTrace, keys)
                    };
                }

                index++;
            }

            if (changeSet.Any(_ => _.ValidationErrors?.Any() == true))
            {
                return;
            }

            tsc.Complete();
        }

        async Task<bool> IsWipAvailableForDiscountTransfer(int entityKey, int transKey, int wipSeqKey)
        {
            var r = await _dbContext.Set<WorkInProgress>()
                                   .AnyAsync(wip => wip.EntityId == entityKey
                                                   && wip.TransactionId == transKey
                                                   && wip.WipSequenceNo == wipSeqKey
                                                   && wip.IsDiscount != 1
                                                   && (wip.IsMargin == false || wip.IsMargin == null));

            return r;
        }

        async Task<AdjustWipItem> GetDiscountItem(int entityKey, int transKey, int wipSeqKey, AdjustWipItem adjustedWipItem = null)
        {
            var discountedWipItem = await (from wip in _dbContext.Set<WorkInProgress>()
                                           where wip.EntityId == entityKey
                                                 && wip.TransactionId == transKey
                                                 && wip.IsDiscount == 1
                                                 && (wip.IsMargin == false || wip.IsMargin == null)
                                                 && wip.Status == TransactionStatus.Active
                                                 && wip.WipSequenceNo != wipSeqKey
                                           select new AdjustWipItem
                                           {
                                               EntityKey = wip.EntityId,
                                               TransKey = wip.TransactionId,
                                               WipSeqNo = wip.WipSequenceNo,
                                               LogDateTimeStamp = wip.LogDateTimeStamp,
                                               NewNarrativeKey = wip.NarrativeId,
                                               NewDebitNoteText = wip.ShortNarrative ?? wip.LongNarrative
                                           }).FirstOrDefaultAsync();

            if (discountedWipItem == null)
            {
                return null;
            }

            if (adjustedWipItem == null)
            {
                return discountedWipItem;
            }

            discountedWipItem.NewTransKey = adjustedWipItem.NewTransKey;
            discountedWipItem.TransDate = adjustedWipItem.TransDate;
            discountedWipItem.ReasonCode = adjustedWipItem.ReasonCode;
            discountedWipItem.RequestedByStaffKey = adjustedWipItem.RequestedByStaffKey;
            discountedWipItem.AdjustmentType = adjustedWipItem.AdjustmentType;

            switch (adjustedWipItem.AdjustmentType)
            {
                case (int) TransactionType.CaseWipTransfer:
                    discountedWipItem.NewCaseKey = adjustedWipItem.NewCaseKey;
                    break;
                case (int) TransactionType.DebtorWipTransfer:
                    discountedWipItem.NewAcctClientKey = adjustedWipItem.NewAcctClientKey;
                    break;
                case (int) TransactionType.StaffWipTransfer:
                    discountedWipItem.NewStaffKey = adjustedWipItem.NewStaffKey;
                    break;
                case (int) TransactionType.ProductWipTransfer:
                    discountedWipItem.NewProductKey = adjustedWipItem.NewProductKey;
                    break;
                default:
                    return null;
            }

            return discountedWipItem;
        }
    }
}