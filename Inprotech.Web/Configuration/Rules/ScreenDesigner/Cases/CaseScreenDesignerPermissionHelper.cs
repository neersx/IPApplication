using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases
{
    public interface ICaseScreenDesignerPermissionHelper
    {
        bool CanEditProtected();
        bool CanEdit(Criteria criteria);
        bool CanEdit(Criteria criteria, out bool editBlockedByDescendants);
        void EnsureDeletePermission(Criteria criteria);
        void EnsureEditPermission(int criteriaId);
        void EnsureEditPermission(Criteria criteria);
        void GetEditProtectionLevelFlags(Criteria criteria, out bool isEditProtectionBlockedByParent, out bool isEditProtectionBlockedByDescendants);
        void EnsureEditProtectionLevelAllowed(Criteria criteria, bool newProtectedFlag);
    }

    internal class CaseScreenDesignerPermissionHelper : ICaseScreenDesignerPermissionHelper
    {
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IInheritance _inheritance;

        public CaseScreenDesignerPermissionHelper(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider, IInheritance inheritance)
        {
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
            _inheritance = inheritance;
        }

        public bool CanEdit(Criteria criteria)
        {
            var hasProtectedDescendants = _inheritance.CheckAnyProtectedDescendantsInTree(criteria.Id);
            return CanEdit(criteria, hasProtectedDescendants);
        }

        public bool CanEdit(Criteria criteria, out bool isEditBlockedByDescendants)
        {
            var hasProtectedDescendants = _inheritance.CheckAnyProtectedDescendantsInTree(criteria.Id);
            isEditBlockedByDescendants = IsEditBlockedByDescendants(criteria, hasProtectedDescendants);
            return CanEdit(criteria, hasProtectedDescendants);
        }

        public void EnsureDeletePermission(Criteria criteria)
        {
            var canDelete = criteria.IsProtected ? CanEditProtected() : CanEditNonProtected() || CanEditProtected();
            if (!canDelete)
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }
        }

        public bool CanEditProtected()
        {
            return _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules);
        }

        public void EnsureEditPermission(int criteriaId)
        {
            var criteria = _dbContext.Set<Criteria>().WherePurposeCode(CriteriaPurposeCodes.WindowControl).Single(_ => _.Id == criteriaId);
            if (!CanEdit(criteria))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }
        }

        public void EnsureEditPermission(Criteria criteria)
        {
            if (!CanEdit(criteria))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }
        }

        public void GetEditProtectionLevelFlags(Criteria criteria, out bool isEditProtectionBlockedByParent, out bool isEditProtectionBlockedByDescendants)
        {
            isEditProtectionBlockedByParent = false;
            isEditProtectionBlockedByDescendants = false;

            var hasProtectedDescendants = _inheritance.CheckAnyProtectedDescendantsInTree(criteria.Id);
            if (!CanEdit(criteria, hasProtectedDescendants)) return;

            var parentCriteria = _dbContext.Set<Inherits>().Include(_ => _.FromCriteria).SingleOrDefault(i => i.CriteriaNo == criteria.Id);
            if (parentCriteria != null)
            {
                // can't make criteria protected if its parent is unprotected
                isEditProtectionBlockedByParent = !parentCriteria.FromCriteria.IsProtected && !criteria.IsProtected;
            }

            // can't make criteria unprotected if it has protected descendants
            isEditProtectionBlockedByDescendants = criteria.IsProtected && hasProtectedDescendants;
        }

        public void EnsureEditProtectionLevelAllowed(Criteria criteria, bool newProtectedFlag)
        {
            bool cantMakeCriteriaProtected;
            bool cantMakeCriteriaUnprotected;

            GetEditProtectionLevelFlags(criteria, out cantMakeCriteriaProtected, out cantMakeCriteriaUnprotected);

            if (newProtectedFlag && cantMakeCriteriaProtected)
            {
                throw new Exception($"Cannot make criteria {criteria.Id} protected because parent is unprotected");
            }
            if (!newProtectedFlag && cantMakeCriteriaUnprotected)
            {
                throw new Exception($"Cannot make criteria {criteria.Id} unprotected because it has protected descendants");
            }
        }

        bool CanEdit(Criteria criteria, bool hasProtectedDescendants)
        {
            // Treat criteria as protected if it has protected descendants
            if (criteria.IsProtected || hasProtectedDescendants)
            {
                return CanEditProtected();
            }

            return CanEditNonProtected() || CanEditProtected();
        }

        bool IsEditBlockedByDescendants(Criteria criteria, bool hasProtectedDescendants)
        {
            var canEditProtected = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules);
            var canEditNonProtected = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules);

            // Special scenario DR-24124
            return canEditNonProtected && !canEditProtected && !criteria.IsProtected && hasProtectedDescendants;
        }

        bool CanEditNonProtected()
        {
            return _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules);
        }
    }
}
