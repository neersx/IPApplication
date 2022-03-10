using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.CaseSource.Innography
{
    public interface INationalCasesResolver
    {
        IQueryable<int?> FindExclusions(string systemCode);
    }

    public class NationalCasesResolver : INationalCasesResolver
    {
        readonly IDbContext _dbContext;

        public NationalCasesResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<int?> FindExclusions(string systemCode)
        {
            var applicationNo = from o in _dbContext.Set<OfficialNumber>()
                                  where o.IsCurrent == 1 && o.NumberTypeId == 
                                        DbFuncs.ResolveMapping(KnownMapStructures.NumberType, KnownEncodingSchemes.CpaXml, "Application", systemCode)
                                  select new
                                  {
                                      o.CaseId,
                                      Number = DbFuncs.StripNonAlphanumerics(o.Number)
                                  };

            var registrationNos = from o in _dbContext.Set<OfficialNumber>()
                                  where o.IsCurrent == 1 && o.NumberTypeId == 
                                        DbFuncs.ResolveMapping(KnownMapStructures.NumberType, KnownEncodingSchemes.CpaXml, "Registration/Grant", systemCode)
                                  select new
                                  {
                                      o.CaseId,
                                      Number = DbFuncs.StripNonAlphanumerics(o.Number)
                                  };

            var nationalCases = from d in _dbContext.Set<RelatedCase>()
                                join parentApplicationNos in applicationNo on d.CaseId equals parentApplicationNos.CaseId into parentApplicationNosResult
                                from parentApplicationNos in parentApplicationNosResult.DefaultIfEmpty()
                                join parentRegistrationNos in registrationNos on d.CaseId equals parentRegistrationNos.CaseId into parentRegistrationNosResult
                                from parentRegistrationNos in parentRegistrationNosResult.DefaultIfEmpty()
                                join childApplicationNos in applicationNo on d.RelatedCaseId equals childApplicationNos.CaseId into childApplicationNosResult
                                from childApplicationNos in childApplicationNosResult.DefaultIfEmpty()
                                join childRegistrationNos in registrationNos on d.RelatedCaseId equals childRegistrationNos.CaseId into childRegistrationNosResult
                                from childRegistrationNos in childRegistrationNosResult.DefaultIfEmpty()
                                where d.Relationship == KnownRelations.DesignatedCountry1
                                      && (parentApplicationNos == null || childApplicationNos == null || parentApplicationNos.Number == childApplicationNos.Number)
                                      && (parentRegistrationNos == null || childRegistrationNos == null || parentRegistrationNos.Number == childRegistrationNos.Number)
                                select d.RelatedCaseId;

            return nationalCases;
        }
    }
}
