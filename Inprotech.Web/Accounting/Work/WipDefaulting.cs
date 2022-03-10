using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Accounting.Work
{
    public interface IWipDefaulting
    {
        Task<WipDefaults> ForCase(WipTemplateFilterCriteria filterCriteria, int caseKey);

        Task<WipDefaults> ForActivity(WipTemplateFilterCriteria filterCriteria, int? caseKey, string activityKey);
    }

    public class WipDefaulting : IWipDefaulting
    {
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IGetWipDefaultsCommand _getWipDefaultsCommand;

        public WipDefaulting(ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, 
                             IGetWipDefaultsCommand getWipDefaultsCommand)
        {
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _getWipDefaultsCommand = getWipDefaultsCommand;
        }

        public async Task<WipDefaults> ForCase(WipTemplateFilterCriteria filterCriteria, int caseKey)
        {
            var culture = _preferredCultureResolver.Resolve();
            return await _getWipDefaultsCommand.GetWipDefaults(_securityContext.User.Id, culture, filterCriteria, caseKey);
        }

        public async Task<WipDefaults> ForActivity(WipTemplateFilterCriteria filterCriteria, int? caseKey, string activityKey)
        {
            var culture = _preferredCultureResolver.Resolve();
            return await _getWipDefaultsCommand.GetWipDefaults(_securityContext.User.Id, culture, filterCriteria, caseKey, activityKey);
        }
    }
}