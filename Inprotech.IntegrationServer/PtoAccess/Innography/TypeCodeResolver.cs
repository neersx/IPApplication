using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public class InnographyTypeCode
    {
        public int CaseId { get; set; }
        public string TypeCode { get; set; }
    }

    public interface ITypeCodeResolver
    {
        IQueryable<InnographyTypeCode> GetTypeCodes();
    }

    public class TypeCodeResolver : ITypeCodeResolver
    {
        readonly IDbContext _dbContext;

        public TypeCodeResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<InnographyTypeCode> GetTypeCodes()
        {
            return from rc in _dbContext.Set<RelatedCase>()
                   join parent in _dbContext.Set<Case>() on rc.CaseId equals parent.Id into parent1
                   from parent in parent1
                   join ta in _dbContext.Set<TableAttributes>() on new
                       {
                           T = (int?) TableTypes.IPOneDataType,
                           P = KnownTableAttributes.Country,
                           C = parent.CountryId
                       }
                       equals new
                       {
                           T = (int?) ta.SourceTableId,
                           P = ta.ParentTable,
                           C = ta.GenericKey
                       }
                       into ta1
                   from ta in ta1
                   join tc in _dbContext.Set<TableCode>() on new
                       {
                           T = (int?) ta.SourceTableId,
                           C = ta.TableCodeId
                       }
                       equals new
                       {
                           T = (int?) tc.TableTypeId,
                           C = tc.Id
                       }
                       into tc1
                   from tc in tc1
                   where rc.Relationship == KnownRelations.DesignatedCountry1 && rc.RelatedCaseId != null
                   select new InnographyTypeCode
                   {
                       CaseId = (int) rc.RelatedCaseId,
                       TypeCode = tc.UserCode
                   };
        }
    }
}