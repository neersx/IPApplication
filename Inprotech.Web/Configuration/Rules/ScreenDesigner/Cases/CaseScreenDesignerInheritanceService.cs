using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases
{
    public interface ICaseScreenDesignerInheritanceService
    {
        string GetInheritanceTreeXml(IEnumerable<int> criteriaIds);
    }

    public class CaseScreenDesignerInheritanceService : ICaseScreenDesignerInheritanceService
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CaseScreenDesignerInheritanceService(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public string GetInheritanceTreeXml(IEnumerable<int> criteriaIds)
        {
            var result = _dbContext.GetCaseScreenDesignerInheritanceTree(_preferredCultureResolver.Resolve(), criteriaIds).SingleOrDefault();
            return result?.Tree;
        }
    }
}
