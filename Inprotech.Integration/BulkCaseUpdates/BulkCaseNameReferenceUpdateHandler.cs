using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.GlobalCaseChange;
using InprotechKaizen.Model.Persistence;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public interface IBulkCaseNameReferenceUpdateHandler
    {
        Task UpdateNameTypeAsync(BulkCaseUpdatesArgs request, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, IQueryable<GlobalCaseChangeResults> gncCases);
    }

    public class BulkCaseNameReferenceUpdateHandler : IBulkCaseNameReferenceUpdateHandler
    {
        readonly IDbContext _dbContext;

        public BulkCaseNameReferenceUpdateHandler(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task UpdateNameTypeAsync(BulkCaseUpdatesArgs request, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, IQueryable<GlobalCaseChangeResults> gncCases)
        {
            var nameTypeData = request.SaveData.CaseNameReference;

            if (nameTypeData?.NameType == null) return;

            var hierarchyNameType = _dbContext.Set<NameType>().Where(_ => _.PathNameType == nameTypeData.NameType && _.HierarchyFlag == 1).Select(_ => _.NameTypeCode).ToArray();
            var nameTypes = new List<string> {nameTypeData.NameType};
            while (hierarchyNameType.Any())
            {
                nameTypes.AddRange(hierarchyNameType);
                hierarchyNameType = _dbContext.Set<NameType>().Where(_ => hierarchyNameType.Contains(_.PathNameType) && _.HierarchyFlag == 1).Select(_ => _.NameTypeCode).ToArray();
            }

            var namesToBeUpdated = from cn in _dbContext.Set<CaseName>().Where(_ => casesToBeUpdated.Any(c => c.Id == _.CaseId))
                                   join cn1 in _dbContext.Set<CaseName>().Where(_ => _.NameTypeId == nameTypeData.NameType) on
                                       new { caseId = cn.CaseId, nameId = cn.NameId }
                                       equals new { caseId = cn1.CaseId, nameId = cn1.NameId } into cnn
                                   from cn1 in cnn
                                   where nameTypes.Contains(cn.NameTypeId) && (nameTypeData.NameType == cn.NameTypeId || cn.IsInherited == 1)
                                   select cn;

            await _dbContext.UpdateAsync(namesToBeUpdated, x => new CaseName
            {
                Reference = nameTypeData.ToRemove ? string.Empty : nameTypeData.Reference
            });

            var updatedCaseIds = namesToBeUpdated.Select(_ => _.CaseId).Distinct().ToArray();
            
            var gncResults = gncCases.Where(_ => updatedCaseIds.Contains(_.CaseId));
            await _dbContext.UpdateAsync(gncResults, _ => new GlobalCaseChangeResults
            {
                CaseNameReferenceUpdated = true
            });
        }
    }
}