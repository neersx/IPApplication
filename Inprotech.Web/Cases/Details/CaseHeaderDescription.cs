using System.Linq;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseHeaderDescription
    {
        string For(string caseReference);
    }
    public class CaseHeaderDescription : ICaseHeaderDescription
    {
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;

        public CaseHeaderDescription(IDbContext dbContext, IDocItemRunner docItemRunner)
        {
            _dbContext = dbContext;
            _docItemRunner = docItemRunner;
        }
            
        public string For(string caseReference)
        {
            var item = (from v in _dbContext.Set<SiteControl>()
                        join q in _dbContext.Set<DocItem>() on v.StringValue.ToUpper() equals q.Name.ToUpper()
                        where v.ControlId == SiteControls.CaseHeaderDescription
                        select new
                               {
                                   ItemId = q.Id
                               }).SingleOrDefault();

            if (item != null)
            {
                var p = DefaultDocItemParameters.ForDocItemSqlQueries();
                p["gstrEntryPoint"] = caseReference;
                var title = _docItemRunner.Run(item.ItemId, p).ScalarValueOrDefault<string>();
                return title;
            }

            return string.Empty;
        }
    }
}