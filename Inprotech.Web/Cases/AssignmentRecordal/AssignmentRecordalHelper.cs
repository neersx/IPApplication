using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using RelatedCase = InprotechKaizen.Model.Cases.RelatedCase;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    public interface IAssignmentRecordalHelper
    {
        Task<IQueryable<RecordalAffectedCase>> GetAffectedCasesToBeChanged(int caseKey, DeleteAffectedCaseModel affectedCaseModel);
        IQueryable<RecordalAffectedCase> GetAffectedCases(int caseKey, IEnumerable<string> rowKeys);

        void GetAssignmentRecordalRelationship(Case mainCase, out CaseRelation relationship, out CaseRelation reverseRelationship);
        void AddRelatedCase(Case mainCase, Case relatedCase, string countryCode, string officialNumber, CaseRelation relation, CaseRelation reverseRelation, int counter);
        void AddNewOwners(Case @case, string owners);
        void RemoveNewOwners(Case @case, string owners);
        void RemoveRelatedCase(Case mainCase, Case relatedCase, string countryCode, string officialNumber, CaseRelation relation, CaseRelation reverseRelation);
    }
    public class AssignmentRecordalHelper : IAssignmentRecordalHelper
    {
        readonly IDbContext _dbContext;
        readonly IAffectedCases _affectedCases;

        public AssignmentRecordalHelper(IDbContext dbContext, IAffectedCases affectedCases)
        {
            _dbContext = dbContext;
            _affectedCases = affectedCases;
        }
        public async Task<IQueryable<RecordalAffectedCase>> GetAffectedCasesToBeChanged(int caseKey, DeleteAffectedCaseModel affectedCaseModel)
        {
            IQueryable<RecordalAffectedCase> affectedCases = null;
            if (affectedCaseModel.IsAllSelected)
            {
                var allAffectedCasesWithFilter = (await _affectedCases.GetAffectedCasesData(caseKey, new CommonQueryParameters(), affectedCaseModel.Filter)).ToArray();
                if (affectedCaseModel.DeSelectedRowKeys != null && affectedCaseModel.DeSelectedRowKeys.Any())
                {
                    allAffectedCasesWithFilter = allAffectedCasesWithFilter.Where(_ => !affectedCaseModel.DeSelectedRowKeys.Contains(_.RowKey)).ToArray();
                } 
                if(allAffectedCasesWithFilter.Any())
                {
                    affectedCases = GetAffectedCases(caseKey, allAffectedCasesWithFilter.Select(_ => _.RowKey));
                }
            }
            else 
            {
                affectedCases = GetAffectedCases(caseKey, affectedCaseModel.SelectedRowKeys);
            }
            return affectedCases;
        }

        public IQueryable<RecordalAffectedCase> GetAffectedCases(int caseKey, IEnumerable<string> rowKeys)
        {
            return from ac in _dbContext.Set<RecordalAffectedCase>().Where(_ => _.CaseId == caseKey)
                            where rowKeys.Contains( ac.CaseId + "^" + ac.RelatedCaseId + "^" + (ac.RelatedCase != null ? ac.RelatedCase.CountryId : ac.CountryId) + "^" + (ac.RelatedCase != null ? ac.RelatedCase.CurrentOfficialNumber : ac.OfficialNumber))
                            select ac;
        }

        public void GetAssignmentRecordalRelationship(Case mainCase, out CaseRelation relationship, out CaseRelation reverseRelationship)
        {
            relationship = _dbContext.Set<CaseRelation>().FirstOrDefault(_ => _.Relationship == KnownRelations.AssignmentRecordal);

            var validRelationships = _dbContext.Set<ValidRelationship>().Where(_ => _.PropertyTypeId == mainCase.PropertyTypeId && _.RelationshipCode == KnownRelations.AssignmentRecordal);

            var validRelationship = !string.IsNullOrWhiteSpace(mainCase.CountryId) && validRelationships.Any(_ => _.CountryId == mainCase.CountryId)
                ? validRelationships.FirstOrDefault(_ => _.CountryId == mainCase.CountryId)
                : validRelationships.FirstOrDefault(_ => _.CountryId == KnownValues.DefaultCountryCode);

            reverseRelationship = validRelationship?.ReciprocalRelationship;
        }
        public void AddRelatedCase(Case mainCase, Case relatedCase, string countryCode, string officialNumber, CaseRelation relation, CaseRelation reverseRelation, int counter)
        {
            if (relatedCase != null)
            {
                if(_dbContext.Set<RelatedCase>().Any(_ => _.CaseId == mainCase.Id && _.RelatedCaseId == relatedCase.Id && _.Relationship == relation.Relationship)) return;
            }
            else
            {
                if(_dbContext.Set<RelatedCase>().Any(_ => _.CaseId == mainCase.Id && _.RelatedCaseId == null && _.CountryCode == countryCode && _.OfficialNumber == officialNumber && _.Relationship == relation.Relationship)) return;
            }
            
            var relationship = _dbContext.Set<RelatedCase>().Where(_ => _.CaseId == mainCase.Id);
            var relationshipNo = relationship.Any() ? relationship.Max(_ => _.RelationshipNo) + 1 : 0;
            _dbContext.Set<RelatedCase>().Add(new RelatedCase(mainCase.Id, countryCode, officialNumber, relation, relatedCase?.Id) {RelationshipNo = relationshipNo + counter, RecordalFlags = 0});

            if (relatedCase == null || reverseRelation == null) return;

            var reverseRelationships = _dbContext.Set<RelatedCase>().Where(_ => _.CaseId == relatedCase.Id);
            var reverseRelationshipNo = reverseRelationships.Any() ? reverseRelationships.Max(_ => _.RelationshipNo) + 1 : 0;
            _dbContext.Set<RelatedCase>().Add(new RelatedCase(relatedCase.Id, null, null, reverseRelation, mainCase.Id){RelationshipNo = reverseRelationshipNo + counter});
        }

        public void RemoveRelatedCase(Case mainCase, Case relatedCase, string countryCode, string officialNumber, CaseRelation relation, CaseRelation reverseRelation)
        {
            IQueryable<RelatedCase> relatedCases;
            if (relatedCase != null)
            {
                relatedCases = _dbContext.Set<RelatedCase>().Where(_ => _.CaseId == mainCase.Id && _.Relationship == relation.Relationship && 
                                                                            _.RelatedCaseId == relatedCase.Id);
            }
            else
            {
                relatedCases = _dbContext.Set<RelatedCase>().Where(_ => _.CaseId == mainCase.Id && _.Relationship == relation.Relationship && 
                                                                           _.CountryCode == countryCode && _.OfficialNumber == officialNumber);
                
            }
            if(relatedCases.Any()) _dbContext.RemoveRange(relatedCases);

            if (relatedCase == null || reverseRelation == null) return;
            
            var reverseRelatedCases = _dbContext.Set<RelatedCase>().Where(_ => _.CaseId == relatedCase.Id && _.RelatedCaseId == mainCase.Id && _.Relationship == reverseRelation.Relationship);
            if(reverseRelatedCases.Any()) _dbContext.RemoveRange(reverseRelatedCases);
        }

        public void AddNewOwners(Case @case, string owners)
        {
            var ownerList = owners.Split(',');

            var nameType = _dbContext.Set<NameType>().FirstOrDefault(_ => _.NameTypeCode == KnownNameTypes.NewOwner);
            var caseNames = _dbContext.Set<CaseName>().Where(_ => _.CaseId == @case.Id && _.NameTypeId == KnownNameTypes.NewOwner);
            var seq = caseNames.Any() ? (short)(caseNames.Max(_ => _.Sequence) + 1) : (short) 0 ;
            foreach (var owner in ownerList)
            {
                int.TryParse(owner, out var ownerId);
                var name = _dbContext.Set<Name>().FirstOrDefault(_ => _.Id == ownerId);
                if (name != null)
                {
                    _dbContext.Set<CaseName>().Add(new CaseName(@case, nameType, name, seq++) { AddressCode = name.StreetAddressId ?? name.PostalAddressId, IsDerivedAttentionName = 1});
                }
            }
        }

        public void RemoveNewOwners(Case @case, string owners)
        {
            if(string.IsNullOrWhiteSpace(owners)) return;
            
            var ownerList = owners.Split(',');
            var caseNames = _dbContext.Set<CaseName>().Where(_ => _.CaseId == @case.Id && _.NameTypeId == KnownNameTypes.NewOwner && ownerList.Contains(_.NameId.ToString()));
            if (caseNames.Any())
            {
                _dbContext.RemoveRange(caseNames);
            }
        }
    }
}
