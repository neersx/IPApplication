using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.CaseSupportData
{
    public interface ICaseAttributes
    {
        IEnumerable<KeyValuePair<string, string>> Get();
    }

    public class CaseAttributes : ICaseAttributes
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CaseAttributes(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<KeyValuePair<string, string>> Get()
        {
            var culture = _preferredCultureResolver.Resolve();
            var caseTypes = _dbContext.Set<CaseType>().Select(_ => new { Name = _.Name.ToUpper() + "/" });
            return _dbContext.Set<SelectionTypes>()
                             .Where(s => caseTypes.Any(_ => s.ParentTable.StartsWith(_.Name)))
                             .OrderBy(_ => _.TableType.Name)
                             .Select(s => new
                             {
                                 Key = s.TableType.Id,
                                 Value = DbFuncs.GetTranslation(s.TableType.Name, null, s.TableType.NameTId, culture)
                             })
                             .Distinct()
                             .ToDictionary(k => k.Key.ToString(), v => v.Value).ToList();
        }
    }
}