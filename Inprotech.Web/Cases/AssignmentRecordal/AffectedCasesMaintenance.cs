using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    public interface IAffectedCasesMaintenance
    {
        Task<dynamic> DeleteAffectedCases(int caseKey, DeleteAffectedCaseModel rowKeys);
        Task AddRecordalAffectedCases(RecordalAffectedCaseRequest model);
        Task<IEnumerable<Inprotech.Web.Picklists.Case>> AddAffectedCaseValidation(ExternalAffectedCaseValidateModel model);
    }
    public class AffectedCasesMaintenance : IAffectedCasesMaintenance
    {
        readonly IDbContext _dbContext;
        readonly IAssignmentRecordalHelper _assignmentRecordalHelper;
        readonly ITransactionRecordal _transactionRecordal;
        readonly ISiteConfiguration _siteConfiguration;
        readonly IComponentResolver _componentResolver;

        public AffectedCasesMaintenance(IDbContext dbContext, IAssignmentRecordalHelper assignmentRecordalHelper, ITransactionRecordal transactionRecordal, ISiteConfiguration siteConfiguration, IComponentResolver componentResolver)
        {
            _dbContext = dbContext;
            _assignmentRecordalHelper = assignmentRecordalHelper;
            _transactionRecordal = transactionRecordal;
            _siteConfiguration = siteConfiguration;
            _componentResolver = componentResolver;
        }

        public async Task<dynamic> DeleteAffectedCases(int caseKey, DeleteAffectedCaseModel affectedCaseModel)
        {
            if (affectedCaseModel == null) throw new ArgumentNullException();

            var affectedCases = await _assignmentRecordalHelper.GetAffectedCasesToBeChanged(caseKey, affectedCaseModel);

            var affectedCasesCanNotBeDeleted = affectedCases.Where(_ => _.Status == AffectedCaseStatus.Recorded);
            var cannotDeleteAffectedCaseRowKeys = affectedCasesCanNotBeDeleted.Select(_ => caseKey + "^" + _.RelatedCaseId + "^" + (_.RelatedCase != null ? _.RelatedCase.CountryId : _.CountryId) + "^" + (_.RelatedCase != null ? _.RelatedCase.CurrentOfficialNumber : _.OfficialNumber)).Distinct().ToList();

            var affectedCasesToBeDeleted = await (from ac in affectedCases
                                                  join acd in affectedCasesCanNotBeDeleted on new { a = ac.CaseId, b = ac.RelatedCaseId, c = ac.CountryId, d = ac.OfficialNumber }
                                                      equals new { a = acd.CaseId, b = acd.RelatedCaseId, c = acd.CountryId, d = acd.OfficialNumber } into acd1
                                                  from acd in acd1.DefaultIfEmpty()
                                                  where acd == null
                                                  select ac).ToArrayAsync();

            var affectedCasesDeletedCount = affectedCasesToBeDeleted.Length;
            if (affectedCasesToBeDeleted.Any())
            {              
                var @case = _dbContext.Set<Case>().First(_ => _.Id == caseKey);
                _assignmentRecordalHelper.GetAssignmentRecordalRelationship(@case, out var relationship, out var reverseRelationship);
                var stepElementsWithOwners = _dbContext.Set<RecordalStepElement>().Where(_ => _.CaseId == @case.Id
                                                                                                   && _.EditAttribute == KnownRecordalEditAttributes.Mandatory
                                                                                                   && _.Element.Code == KnownRecordalElementValues.NewName
                                                                                                   && _.NameTypeCode == KnownNameTypes.Owner).ToArray();
                
                using var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled);
                var reasonNo = _siteConfiguration.TransactionReason ? _siteConfiguration.ReasonInternalChange : null;
                _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reasonNo, _componentResolver.Resolve(KnownComponents.Case));

                foreach (var afc in affectedCasesToBeDeleted)
                {
                    _assignmentRecordalHelper.RemoveRelatedCase(afc.Case, afc.RelatedCase, afc.CountryId, afc.OfficialNumber, relationship, reverseRelationship);

                    var ownerStep = stepElementsWithOwners.FirstOrDefault(_ => _.RecordalStepId == afc.RecordalStepSeq);
                    if (afc.RelatedCaseId.HasValue && ownerStep != null)
                    {
                        _assignmentRecordalHelper.RemoveNewOwners(afc.RelatedCase, ownerStep.ElementValue);
                    }
                    _dbContext.Set<RecordalAffectedCase>().Remove(afc);
                }

                await _dbContext.SaveChangesAsync();
                tsc.Complete();
            }

            var result = !cannotDeleteAffectedCaseRowKeys.Any() ? "success" : affectedCasesDeletedCount == 0 ? "error" : "partialComplete";

            return new
            {
                Result = result,
                CannotDeleteCaselistIds = cannotDeleteAffectedCaseRowKeys
            };
        }

        public async Task AddRecordalAffectedCases(RecordalAffectedCaseRequest model)
        {
            var @case = await _dbContext.Set<Case>().FirstOrDefaultAsync(x => x.Id == model.CaseId);
            var country = await _dbContext.Set<Country>().FirstOrDefaultAsync(x => x.Id == model.Jurisdiction);
            var affectedMainCases = _dbContext.Set<RecordalAffectedCase>().Where(_ => _.CaseId == @case.Id);
            var maxSeq = affectedMainCases.Any() ? affectedMainCases.Max(_ => _.SequenceNo) : -1;

            _assignmentRecordalHelper.GetAssignmentRecordalRelationship(@case, out var relationship, out var reverseRelationship);

            using var tsc = _dbContext.BeginTransaction(IsolationLevel.ReadCommitted, TransactionScopeAsyncFlowOption.Enabled);
            var reasonNo = _siteConfiguration.TransactionReason ? _siteConfiguration.ReasonInternalChange : null;
            _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reasonNo, _componentResolver.Resolve(KnownComponents.Case));

            var stepCounter = 0;
            foreach (var step in model.RecordalSteps)
            {
                var recordalType = await _dbContext.Set<RecordalType>().FirstOrDefaultAsync(x => x.Id == step.RecordalTypeNo);
                var newNameRecordalElement = await _dbContext.Set<RecordalStepElement>().FirstOrDefaultAsync(_ => _.RecordalStepId == step.RecordalStepSequence
                                                                                                               && _.CaseId == model.CaseId
                                                                                                               && _.EditAttribute == KnownRecordalEditAttributes.Mandatory
                                                                                                               && _.Element.Code == "NEWNAME"
                                                                                                            && _.NameTypeCode == KnownNameTypes.Owner);
                if (model.RelatedCases?.Length > 0)
                {
                    var counter = 0;
                    foreach (var caseId in model.RelatedCases)
                    {
                        var exists = _dbContext.Set<RecordalAffectedCase>().Any(x => x.CaseId == @case.Id && x.RelatedCaseId == caseId && x.RecordalTypeNo == step.RecordalTypeNo && x.RecordalStepSeq == step.RecordalStepSequence);
                        if (exists) continue;

                        var relatedCase = await _dbContext.Set<Case>().FirstAsync(x => x.Id == caseId);
                        _dbContext.Set<RecordalAffectedCase>().Add(new RecordalAffectedCase(@case, relatedCase, ++maxSeq, recordalType, step.RecordalStepSequence, AffectedCasesStatus.NotFiled));

                        if (stepCounter == 0)
                        {
                            _assignmentRecordalHelper.AddRelatedCase(@case, relatedCase, null, null, relationship, reverseRelationship, counter++);
                        }

                        if (!string.IsNullOrWhiteSpace(newNameRecordalElement?.ElementValue))
                        {
                            _assignmentRecordalHelper.AddNewOwners(relatedCase, newNameRecordalElement.ElementValue);
                        }
                    }
                }
                else
                {
                    var exists = _dbContext.Set<RecordalAffectedCase>().Any(x => x.CaseId == @case.Id && x.CountryId == model.Jurisdiction && x.OfficialNumber == model.OfficialNo && x.RecordalTypeNo == step.RecordalTypeNo && x.RecordalStepSeq == step.RecordalStepSequence);
                    if (exists) continue;

                    _dbContext.Set<RecordalAffectedCase>().Add(new RecordalAffectedCase(@case, recordalType, country, model.OfficialNo, step.RecordalStepSequence, ++maxSeq, AffectedCasesStatus.NotFiled));
                    _assignmentRecordalHelper.AddRelatedCase(@case, null, country?.Id, model.OfficialNo, relationship, null, 0);
                }
                stepCounter++;
            }
            await _dbContext.SaveChangesAsync();
            tsc.Complete();
        }

        public async Task<IEnumerable<Inprotech.Web.Picklists.Case>> AddAffectedCaseValidation(ExternalAffectedCaseValidateModel model)
        {
            if (model == null || string.IsNullOrWhiteSpace(model.Country) || string.IsNullOrWhiteSpace(model.OfficialNo)) return null;

            var number = model.OfficialNo.StripNonAlphanumerics();

            var caseIndexes = _dbContext.Set<CaseIndexes>()
                                         .Where(_ => _.Source == CaseIndexSource.OfficialNumbers && _.GenericIndex == number);

            return await (from c in _dbContext.Set<Case>()
                                              .Where(_ => _.Country.Id == model.Country && caseIndexes.Any(i => i.CaseId == _.Id))
                          select new Inprotech.Web.Picklists.Case
                          {
                              Key = c.Id,
                              Code = c.Irn
                          }).ToArrayAsync();
        }
    }
}
