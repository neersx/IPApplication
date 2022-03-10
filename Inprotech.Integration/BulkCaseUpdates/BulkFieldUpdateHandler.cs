using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.GlobalCaseChange;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Rules;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public interface IBulkFieldUpdateHandler
    {
        Task<BulkUpdateCases> GetCases(int[] caseIds);
        Task<BulkUpdateResult> Update(IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkCaseUpdatesArgs request);
    }

    public class BulkFieldUpdateHandler : IBulkFieldUpdateHandler
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ICaseAuthorization _caseAuthorization;
        readonly Func<DateTime> _now;
        readonly IBulkCaseTextUpdateHandler _bulkCaseTextUpdateHandler;
        readonly IBulkFileLocationUpdateHandler _bulkFileLocationUpdateHandler;
        readonly IBulkCaseNameReferenceUpdateHandler _bulkCaseNameReferenceUpdateHandler;
        readonly IBulkCaseStatusUpdateHandler _bulkCaseStatusUpdateHandler;
        readonly IBulkPolicingHandler _bulkPolicingHandler;

        public BulkFieldUpdateHandler(
            IDbContext dbContext,
            ISecurityContext securityContext,
            ICaseAuthorization caseAuthorization,
            Func<DateTime> now,
            IBulkCaseTextUpdateHandler bulkCaseTextUpdateHandler,
            IBulkCaseNameReferenceUpdateHandler bulkCaseNameReferenceUpdateHandler,
            IBulkFileLocationUpdateHandler bulkFileLocationUpdateHandler,
            IBulkCaseStatusUpdateHandler bulkCaseStatusUpdateHandler,
            IBulkPolicingHandler bulkPolicingHandler
            )
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _caseAuthorization = caseAuthorization;
            _now = now;
            _bulkCaseTextUpdateHandler = bulkCaseTextUpdateHandler;
            _bulkCaseNameReferenceUpdateHandler = bulkCaseNameReferenceUpdateHandler;
            _bulkFileLocationUpdateHandler = bulkFileLocationUpdateHandler;
            _bulkCaseStatusUpdateHandler = bulkCaseStatusUpdateHandler;
            _bulkPolicingHandler = bulkPolicingHandler;
        }

        public async Task<BulkUpdateCases> GetCases(int[] caseIds)
        {
            var listOfAuthorizedCases = (from ap in await _caseAuthorization.UpdatableCases(caseIds)
                                           select ap).ToArray();
            var listOfUnAuthorizedCases = caseIds.Where(_ => !listOfAuthorizedCases.Contains(_)).ToArray();

            return new BulkUpdateCases
            {
                AuthorizedCases = listOfAuthorizedCases,
                UnauthorizedCases = listOfUnAuthorizedCases
            };
        }

        public async Task<BulkUpdateResult> Update(IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkCaseUpdatesArgs request)
        {
            var bulkUpdateResult = new BulkUpdateResult { ProcessId = request.ProcessId };

            var gncResults = _dbContext.Set<GlobalCaseChangeResults>().Where(_ => _.Id == request.ProcessId && casesToBeUpdated.Any(x => x.Id == _.CaseId));

            if (!string.IsNullOrWhiteSpace(request.CaseAction))
            {
                await _bulkPolicingHandler.BulkPolicingAsync(request, casesToBeUpdated, gncResults);
            }
            else
            {
                await UpdateCaseOfficeAsync(request.SaveData.CaseOffice, casesToBeUpdated, bulkUpdateResult);

                await UpdateCaseFamilyAsync(request.SaveData.CaseFamily, casesToBeUpdated, bulkUpdateResult);

                await UpdateProfitCentreAsync(request.SaveData.ProfitCentre, casesToBeUpdated, bulkUpdateResult);

                await UpdateTitleMarkAsync(request.SaveData.TitleMark, casesToBeUpdated, bulkUpdateResult);

                await UpdateTypeOfMarkAsync(request.SaveData.TypeOfMark, casesToBeUpdated, bulkUpdateResult);

                await UpdatePurchaseOrderAsync(request.SaveData.PurchaseOrder, casesToBeUpdated, bulkUpdateResult);

                await UpdateEntitySizeAsync(request.SaveData.EntitySize, casesToBeUpdated, bulkUpdateResult);

                await _bulkFileLocationUpdateHandler.UpdateFileLocationAsync(request, casesToBeUpdated, bulkUpdateResult);

                await UpdateGncResults(gncResults, bulkUpdateResult);

                await _bulkCaseNameReferenceUpdateHandler.UpdateNameTypeAsync(request, casesToBeUpdated, gncResults);

                await _bulkCaseStatusUpdateHandler.UpdateCaseStatusAsync(request.SaveData, casesToBeUpdated, gncResults);
            }

            bulkUpdateResult.HasInvalidCasesForGoodsWithClass = await _bulkCaseTextUpdateHandler.UpdateTextTypeAsync(request, casesToBeUpdated, gncResults);

            return bulkUpdateResult;
        }

        async Task UpdateGncResults(IQueryable<GlobalCaseChangeResults> gncResults, BulkUpdateResult bur)
        {
            if (bur.HasEntitySizeUpdated || bur.HasFamilyUpdated || bur.HasOfficeUpdated || 
                bur.HasProfitCentreUpdated || bur.HasTitleUpdated || bur.HasTypeOfMarkUpdated || 
                bur.HasPurchaseOrderUpdated || bur.HasFileLocationUpdated)
            {
                await _dbContext.UpdateAsync(gncResults, _ => new GlobalCaseChangeResults
                {
                    ProfitCentreCodeUpdated = bur.HasProfitCentreUpdated,
                    OfficeUpdated = bur.HasOfficeUpdated,
                    FamilyUpdated = bur.HasFamilyUpdated,
                    TitleUpdated = bur.HasTitleUpdated,
                    TypeOfMarkUpdated = bur.HasTypeOfMarkUpdated,
                    PurchaseOrderNoUpdated = bur.HasPurchaseOrderUpdated,
                    EntitySizeUpdated = bur.HasEntitySizeUpdated,
                    FileLocationUpdated = bur.HasFileLocationUpdated
                });
            }
        }

        async Task UpdateCaseOfficeAsync(BulkSaveData data, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkUpdateResult bulkUpdateResult)
        {
            if (data == null) return;
            await _dbContext.UpdateAsync(casesToBeUpdated, _ => new InprotechKaizen.Model.Cases.Case
            {
                OfficeId = GetIntegerValue(data)
            });

            InsertPolicingRequest(casesToBeUpdated.Select(_ => _.Id).ToArray());

            bulkUpdateResult.HasOfficeUpdated = true;
        }

        void InsertPolicingRequest(int[] cases)
        {
            var now = _now();
            var profileId = _securityContext.User.Profile?.Id;
            var openActions = (from o in _dbContext.Set<OpenAction>()
                               where cases.Contains(o.CaseId)
                                     && o.PoliceEvents == 1
                                     && (o.CriteriaId == null ||
                                         o.CriteriaId != DbFuncs.GetCriteriaNo(o.CaseId, CriteriaPurposeCodes.EventsAndEntries, o.ActionId, now, profileId))
                               select new
                               {
                                   o.CaseId,
                                   o.ActionId,
                                   o.CriteriaId,
                                   o.Cycle
                               }).ToArray();

            if (!openActions.Any()) return;
            var count = 1;
            _dbContext.AddRange(openActions.Select(_ => new PolicingRequest(_.CaseId)
            {
                DateEntered = now,
                SequenceNo = count,
                Name = "GLOBAL-" + now.ToString("yyyy-MM-ddTHH:mm:ss.fff") + count++,
                IsSystemGenerated = 1,
                OnHold = 0,
                Action = _.ActionId,
                CaseId = _.CaseId,
                EventCycle = _.Cycle,
                TypeOfRequest = 1,
                IdentityId = _securityContext.User.Id
            }));
        }

        async Task UpdateCaseFamilyAsync(BulkSaveData data, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkUpdateResult bulkUpdateResult)
        {
            if (data == null) return;

            await _dbContext.UpdateAsync(casesToBeUpdated, _ => new InprotechKaizen.Model.Cases.Case
            {
                FamilyId = GetStringValue(data)
            });

            bulkUpdateResult.HasFamilyUpdated = true;
        }

        async Task UpdateProfitCentreAsync(BulkSaveData data, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkUpdateResult bulkUpdateResult)
        {
            if (data == null) return;

            await _dbContext.UpdateAsync(casesToBeUpdated, _ => new InprotechKaizen.Model.Cases.Case
            {
                ProfitCentreCode = GetStringValue(data)
            });

            bulkUpdateResult.HasProfitCentreUpdated = true;
        }

        async Task UpdateTitleMarkAsync(BulkSaveData data, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkUpdateResult bulkUpdateResult)
        {
            if (data == null) return;

            await _dbContext.UpdateAsync(casesToBeUpdated, _ => new InprotechKaizen.Model.Cases.Case
            {
                Title = GetStringValue(data)
            });

            bulkUpdateResult.HasTitleUpdated = true;
        }

        async Task UpdateTypeOfMarkAsync(BulkSaveData data, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkUpdateResult bulkUpdateResult)
        {
            if (data == null) return;
            await _dbContext.UpdateAsync(casesToBeUpdated, _ => new InprotechKaizen.Model.Cases.Case
            {
                TypeOfMarkId = GetIntegerValue(data)
            });

            bulkUpdateResult.HasTypeOfMarkUpdated = true;
        }

        async Task UpdatePurchaseOrderAsync(BulkSaveData data, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkUpdateResult bulkUpdateResult)
        {
            if (data == null) return;

            await _dbContext.UpdateAsync(casesToBeUpdated, _ => new InprotechKaizen.Model.Cases.Case
            {
                PurchaseOrderNo = GetStringValue(data)
            });

            bulkUpdateResult.HasPurchaseOrderUpdated = true;
        }

        async Task UpdateEntitySizeAsync(BulkSaveData data, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkUpdateResult bulkUpdateResult)
        {
            if (data == null) return;
            await _dbContext.UpdateAsync(casesToBeUpdated, _ => new InprotechKaizen.Model.Cases.Case
            {
                EntitySizeId = GetIntegerValue(data)
            });

            bulkUpdateResult.HasEntitySizeUpdated = true;
        }

        static int? GetIntegerValue(BulkSaveData data)
        {
            return data.ToRemove ? (int?)null : int.Parse(data.Key);
        }
        static string GetStringValue(BulkSaveData data)
        {
            return data.ToRemove ? null : data.Key;
        }
    }

    public class BulkUpdateCases
    {
        public int[] AuthorizedCases { get; set; }
        public int[] UnauthorizedCases { get; set; }
    }

    public class BulkUpdateResult
    {
        public int ProcessId { get; set; }
        public bool HasOfficeUpdated { get; set; }
        public bool HasFamilyUpdated { get; set; }
        public bool HasTitleUpdated { get; set; }
        public bool HasTypeOfMarkUpdated { get; set; }
        public bool HasEntitySizeUpdated { get; set; }
        public bool HasPurchaseOrderUpdated { get; set; }
        public bool HasProfitCentreUpdated { get; set; }
        public bool HasFileLocationUpdated { get; set; }
        public bool IsPoliced { get; set; }
        public bool HasInvalidCasesForGoodsWithClass { get; set; }
    }
}
