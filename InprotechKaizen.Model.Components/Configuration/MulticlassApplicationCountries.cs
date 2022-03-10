using System.Linq;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Configuration
{
    public interface IMultipleClassApplicationCountries
    {
        IQueryable<string> Resolve();
    }

    public class MultipleClassApplicationCountries : IMultipleClassApplicationCountries
    {
        readonly IDbContext _dbContext;

        public MultipleClassApplicationCountries(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<string> Resolve()
        {
            return (from t in _dbContext.Set<TableAttributes>()
                    where t.TableCodeId == ProtectedTableCode.MultiClassPropertyApplicationsAllowed
                    select t.GenericKey).Distinct();
        }
    }
}