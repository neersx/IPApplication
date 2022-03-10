using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IImportanceLevelResolver
    {
        int Resolve(User user = null);
        int? GetValidImportanceLevel(int? importanceLevel);
        Task<IEnumerable<Importance>> GetImportanceLevels();
    }

    class ImportanceLevelResolver : IImportanceLevelResolver
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IPreferredCultureResolver _preferredCulture;

        public ImportanceLevelResolver(IDbContext dbContext, ISecurityContext securityContext, ISiteControlReader siteControlReader, IPreferredCultureResolver preferredCulture)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _siteControlReader = siteControlReader;
            _preferredCulture = preferredCulture;
        }

        public int Resolve(User user = null)
        {
            var u = user ?? _securityContext.User;
            var profileAttribute = u?.Profile?.ProfileAttributes?.FirstOrDefault(_ => _.AttributeType == ProfileAttributeType.MinimumImportanceLevel);
            if (profileAttribute != null && int.TryParse(profileAttribute.Value, out int val))
                return val;

            return _siteControlReader.Read<int>(u?.IsExternalUser == true ? SiteControls.ClientImportance : SiteControls.EventsDisplayed);
        }

        public int? GetValidImportanceLevel(int? importanceLevel)
        {
            if (_securityContext.User.IsExternalUser)
            {
                var defaultImportanceLevel = Resolve();
                if (!importanceLevel.HasValue || importanceLevel.Value < defaultImportanceLevel)
                    importanceLevel = defaultImportanceLevel;
            }
            return importanceLevel;
        }

        public async Task<IEnumerable<Importance>> GetImportanceLevels()
        {
            var culture = _preferredCulture.Resolve();
            var importance = await _dbContext.Set<Importance>()
                                             .Select(_ => new CodeDescription
                                             {
                                                 Code = _.Level,
                                                 Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                             })
                                             .ToArrayAsync();

            return importance.Where(_ => new Regex(@"^\d+$").Match(_.Code).Success).Select(_ => new Importance(_.Code, _.Description)).OrderBy(_ => _.LevelNumeric);
        }
    }
}