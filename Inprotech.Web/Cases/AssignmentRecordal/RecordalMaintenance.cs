using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.ApplyRecordal;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    public interface IRecordalMaintenance
    {
        Task<IEnumerable<RecordalRequestData>> GetAffectedCasesForRequestRecordal(RecordalRequest affectedCaseModel);
        Task<dynamic> SaveRequestRecordal(SaveRecordalRequest model);
    }
    public class RecordalMaintenance : IRecordalMaintenance
    {
        readonly IDbContext _dbContext;
        readonly IAssignmentRecordalHelper _helper;
        readonly ISiteControlReader _siteControlReader;
        readonly IPolicingEngine _policingEngine;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _systemTime;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IBus _bus;
        readonly IStaticTranslator _staticTranslator;

        public RecordalMaintenance(IDbContext dbContext, IAssignmentRecordalHelper helper,
                                   ISiteControlReader siteControlReader,
                                   IPolicingEngine policingEngine, 
                                   ISecurityContext securityContext, 
                                   Func<DateTime> systemTime,
                                   IPreferredCultureResolver preferredCultureResolver,
                                   IBus bus,
                                   IStaticTranslator staticTranslator)
        {
            _dbContext = dbContext;
            _helper = helper;
            _siteControlReader = siteControlReader;
            _policingEngine = policingEngine;
            _securityContext = securityContext;
            _systemTime = systemTime;
            _preferredCultureResolver = preferredCultureResolver;
            _bus = bus;
            _staticTranslator = staticTranslator;
        }

        public async Task<IEnumerable<RecordalRequestData>> GetAffectedCasesForRequestRecordal(RecordalRequest affectedCaseModel)
        {
            if (affectedCaseModel == null) throw new ArgumentNullException();

            var model = new DeleteAffectedCaseModel { DeSelectedRowKeys = affectedCaseModel.DeSelectedRowKeys, SelectedRowKeys = affectedCaseModel.SelectedRowKeys, IsAllSelected = affectedCaseModel.IsAllSelected, Filter = affectedCaseModel.Filter};
            var affectedCases = await _helper.GetAffectedCasesToBeChanged(affectedCaseModel.CaseId, model);
            
            return await (from ac in affectedCases
                                 join rs in _dbContext.Set<RecordalStep>().Where(_ => _.CaseId == affectedCaseModel.CaseId) on new { a = ac.CaseId, b = ac.RecordalTypeNo } equals new { a = rs.CaseId, b = rs.TypeId }
                                 where (ac.RecordalStepSeq.HasValue && rs.Id == ac.RecordalStepSeq) || !ac.RecordalStepSeq.HasValue
                                 select new RecordalRequestData
                                 {
                                     SequenceNo = ac.SequenceNo,
                                     CaseId = ac.RelatedCaseId,
                                     CaseReference = ac.RelatedCase != null ? ac.RelatedCase.Irn : null,
                                     CountryCode = ac.RelatedCase != null ? ac.RelatedCase.CountryId : ac.CountryId,
                                     Country = ac.RelatedCase != null ? ac.RelatedCase.Country.Name : ac.Country.Name,
                                     OfficialNo = ac.RelatedCase != null ? ac.RelatedCase.CurrentOfficialNumber : ac.OfficialNumber,
                                     RecordalTypeNo = ac.RecordalTypeNo,
                                     RecordalType = ac.RecordalType.RecordalTypeName,
                                     StepId = rs.StepId,
                                     Status = ac.Status,
                                     RequestDate = ac.RequestDate,
                                     RecordDate = ac.RecordDate,
                                     IsEditable = affectedCaseModel.RequestType == RecordalRequestType.Request ? ac.Status == AffectedCasesStatus.NotFiled : ac.Status == AffectedCasesStatus.Filed
                                 }).OrderBy(_ => _.CaseReference).ThenBy(_ => _.StepId).ToArrayAsync();
        }

        public async Task<dynamic> SaveRequestRecordal(SaveRecordalRequest model)
        {
            if (model == null) throw new ArgumentNullException();

            var affectedCases = _dbContext.Set<RecordalAffectedCase>().Where(_ => _.CaseId == model.CaseId && model.SeqIds.Contains(_.SequenceNo));
            if (!affectedCases.Any()) throw new HttpResponseException(HttpStatusCode.NotFound);

            if (model.RequestType == RecordalRequestType.Request)
            {
                await RequestRecordal(model, affectedCases);
            }
            else if (model.RequestType == RecordalRequestType.Reject)
            {
                await RejectRecordal(model, affectedCases);
            }
            else
            {
                await ApplyRecordal(model, affectedCases);
            }

            return new { Result = "success" };
        }

        async Task RequestRecordal(SaveRecordalRequest model, IQueryable<RecordalAffectedCase> affectedCases)
        {
            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                await affectedCases.ForEachAsync(_ =>
                {
                    _.Status = AffectedCasesStatus.Filed;
                    _.RequestDate = model.RequestedDate;
                });
                await _dbContext.SaveChangesAsync();

                await ImplementRequestEvent(model, affectedCases);

                t.Complete();
            }
        }

        async Task RejectRecordal(SaveRecordalRequest model, IQueryable<RecordalAffectedCase> affectedCases)
        {
            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                await affectedCases.ForEachAsync(_ =>
                {
                    _.Status = AffectedCasesStatus.Rejected;
                    _.RecordDate = model.RequestedDate;
                });

                RemoveNewOwners(model, affectedCases);

                await _dbContext.SaveChangesAsync();
                t.Complete();
            }
        }

        async Task ApplyRecordal(SaveRecordalRequest model, IQueryable<RecordalAffectedCase> affectedCases)
        {
            var culture = _preferredCultureResolver.Resolve();
            var cultureArray = _preferredCultureResolver.ResolveAll().ToArray();
            var successMessage = _staticTranslator.Translate("caseview.affectedCases.applyRecordalProcessed", cultureArray);
            var errorMessage = _staticTranslator.Translate("caseview.affectedCases.applyRecordalFailed", cultureArray);
            var seqIds = string.Join(",", affectedCases.Select(_ => _.SequenceNo));

            await _bus.PublishAsync(new ApplyRecordalArgs
            {
                RecordalCase = model.CaseId,
                RecordalDate = model.RequestedDate,
                RecordalStatus = AffectedCasesStatus.Recorded,
                RunBy = _securityContext.User.Id,
                Culture = culture,
                RecordalSeqIds = seqIds,
                SuccessMessage = successMessage,
                ErrorMessage = errorMessage
            });
        }

        async Task ImplementRequestEvent(SaveRecordalRequest model, IQueryable<RecordalAffectedCase> affectedCases)
        {
            var affectedCasesWithEvents = await affectedCases.Where(_ => _.RelatedCaseId.HasValue && _.RecordalType.RequestEventId.HasValue).ToArrayAsync();
            if (!affectedCasesWithEvents.Any()) { return; }

            var isPoliceImmediatelyFromEvent = affectedCasesWithEvents.Any(_ => _.RecordalType.RequestEvent.ShouldPoliceImmediate);
            var isPoliceImmediately = _siteControlReader.Read<bool>(SiteControls.PoliceImmediately) || _siteControlReader.Read<bool>(SiteControls.PoliceImmediateInBackground);
            int? batchNo = null;
            if (isPoliceImmediately || isPoliceImmediatelyFromEvent)
            {
                batchNo = _policingEngine.CreateBatch();
            }
            var profileId = _securityContext.User.Profile?.Id;
            var now = _systemTime();

            foreach (var afc in affectedCasesWithEvents)
            {
                var caseEvent = AddOrUpdateRequestedCaseEvent(model, afc);
                if(caseEvent == null || afc.RelatedCaseId == null) continue;

                var criteriaNo = DbFuncs.GetCriteriaNo(afc.RelatedCaseId.Value, "E", afc.RecordalType.RequestActionId, now, profileId);
                if (!string.IsNullOrWhiteSpace(afc.RecordalType.RequestActionId))
                {
                    var isActionOpen = _dbContext.Set<OpenAction>().Any(_ => _.CaseId == afc.RelatedCaseId && _.ActionId == afc.RecordalType.RequestActionId && _.Cycle == caseEvent.Cycle && _.PoliceEvents == 1);
                    if (!isActionOpen)
                    {
                        _policingEngine.PoliceEvent(caseEvent, criteriaNo, batchNo, afc.RecordalType.RequestActionId, TypeOfPolicingRequest.OpenAnAction);
                    }
                }
                _policingEngine.PoliceEvent(caseEvent, criteriaNo, batchNo, afc.RecordalType.RequestActionId, TypeOfPolicingRequest.PoliceOccurredEvent);
            }

            await _dbContext.SaveChangesAsync();

            if (isPoliceImmediately || isPoliceImmediatelyFromEvent)
            {
                await _policingEngine.PoliceWithoutTransaction(batchNo);
            }
        }

        CaseEvent AddOrUpdateRequestedCaseEvent(SaveRecordalRequest model, RecordalAffectedCase afc)
        {
            short cycle = 1;
            var caseEvents = _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == afc.RelatedCaseId && _.EventNo == afc.RecordalType.RequestEventId);
            if (caseEvents.Any())
            {
                cycle = caseEvents.Max(_ => _.Cycle);
                var caseEvent = caseEvents.First(_ => _.Cycle == cycle);
                caseEvent.IsOccurredFlag = 1;
                caseEvent.EventDate = model.RequestedDate;
                return caseEvent;
            }

            if (!afc.RelatedCaseId.HasValue || !afc.RecordalType.RequestEventId.HasValue) return null;

            var newCaseEvent = new CaseEvent(afc.RelatedCaseId.Value, afc.RecordalType.RequestEventId.Value, cycle)
            {
                EventDate = model.RequestedDate,
                IsOccurredFlag = 1
            };
            _dbContext.Set<CaseEvent>().Add(newCaseEvent);
            return newCaseEvent;
        }

        void RemoveNewOwners(SaveRecordalRequest model, IQueryable<RecordalAffectedCase> affectedCases)
        {
            var stepElementsWithOwners = _dbContext.Set<RecordalStepElement>().Where(_ => _.CaseId == model.CaseId 
                                                                                          && _.EditAttribute == KnownRecordalEditAttributes.Mandatory
                                                                                          && _.Element.Code == KnownRecordalElementValues.NewName
                                                                                          && _.NameTypeCode == KnownNameTypes.Owner).ToArray();

            if (!stepElementsWithOwners.Any()) return;

            foreach (var afc in affectedCases.Where(_ => _.RelatedCaseId.HasValue).ToArray())
            {
                var ownerStep = stepElementsWithOwners.FirstOrDefault(_ => _.RecordalStepId == afc.RecordalStepSeq);
                if (afc.RelatedCaseId.HasValue && ownerStep != null)
                {
                    _helper.RemoveNewOwners(afc.RelatedCase, ownerStep.ElementValue);
                }
            }
        }
    }
}
