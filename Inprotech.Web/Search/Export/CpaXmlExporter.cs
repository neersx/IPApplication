using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Export
{
    public interface ICpaXmlExporter
    {
        Task<CpaXmlResult> ScheduleCpaXmlImport(string caseIds);
    }

    public class CpaXmlExporter : ICpaXmlExporter
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public CpaXmlExporter(IDbContext dbContext, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public async Task<CpaXmlResult> ScheduleCpaXmlImport(string caseIds)
        {
            var tempStorage = _dbContext.Set<InprotechKaizen.Model.TempStorage.TempStorage>().Add(new InprotechKaizen.Model.TempStorage.TempStorage(caseIds));

            await _dbContext.SaveChangesAsync();

            return _dbContext.GenerateCpaXml(null, tempStorage.Id, _securityContext.User.Id, 1);
        }
    }
}