using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Delete)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Delete)]
    [RoutePrefix("api/configuration/rules/screen-designer/case")]
    public class CaseScreenDesignerController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ICaseScreenDesignerPermissionHelper _permissionHelper;
        readonly ICaseViewSectionsResolver _sectionsResolver;

        public CaseScreenDesignerController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ICaseScreenDesignerPermissionHelper permissionHelper, ICaseViewSectionsResolver sectionsResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _permissionHelper = permissionHelper;
            _sectionsResolver = sectionsResolver;
        }

        [HttpGet]
        [Route("{criteriaId:int}")]
        public dynamic GetScreenDesignerCriteria(int criteriaId)
        {
            var criteria = _dbContext.Set<Criteria>().WherePurposeCode(CriteriaPurposeCodes.WindowControl).Single(_ => _.Id == criteriaId);
            var canEdit = _permissionHelper.CanEdit(criteria, out var editBlockedByDescendants);
            var canEditProtected = _permissionHelper.CanEditProtected();
            var isInherited = _dbContext.Set<Inherits>().Any(c => c.CriteriaNo == criteriaId);
            var isParent = _dbContext.Set<Inherits>().Any(c => c.FromCriteriaNo == criteriaId);
            if (!canEdit)
            {
                var culture = _preferredCultureResolver.Resolve();
                var translation = _dbContext.Set<Criteria>()
                                            .Select(_ => new
                                            {
                                                _.Id,
                                                DescriptionT = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                            }).Single(_ => _.Id == criteriaId);
                criteria.Description = translation.DescriptionT;
            }
            return new
            {
                CanEdit = canEdit,
                EditBlockedByDescendants = editBlockedByDescendants,
                CanEditProtected = canEditProtected,
                HasOffices = _dbContext.Set<Office>().Any(),
                CriteriaId = criteria.Id,
                CriteriaName = criteria.Description,
                criteria.IsProtected,
                IsInherited = isInherited,
                IsHighestParent = isParent && !isInherited
            };
        }
        
        [HttpGet]
        [Route("{criteriaId:int}/sections")]
        public async Task<dynamic> GetCriteriaSections(int criteriaId)
        {
            var res= await _sectionsResolver.ResolveSections(criteriaId);
            return res;
        }

    }
}
