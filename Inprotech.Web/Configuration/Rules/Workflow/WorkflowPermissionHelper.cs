using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IWorkflowPermissionHelper
    {
        bool CanEditProtected();
        bool CanEdit(Criteria criteria);
        bool CanEdit(Criteria criteria, out bool editBlockedByDescendants);
        bool CanEditEvent(Criteria criteria, int eventId, out bool editBlockedByDescendants, out bool isNonConfigurableEvent);
        void EnsureDeletePermission(Criteria criteria);
        void EnsureEditPermission(int criteriaId);
        void EnsureEditPermission(Criteria criteria);
        void EnsureEditEventControlPermission(int criteriaId, int eventId);
        void GetEditProtectionLevelFlags(Criteria criteria, out bool isEditProtectionBlockedByParent, out bool isEditProtectionBlockedByDescendants);
        void EnsureEditProtectionLevelAllowed(Criteria criteria, bool newProtectedFlag);
        bool CanCreateNegativeWorkflow();
    }

    internal class WorkflowPermissionHelper : IWorkflowPermissionHelper
    {
        readonly IDbContext _dbContext;

        readonly int[] _systemEvents =
        {
            (int) KnownEvents.InstructionsReceivedDateForNewCase,
            (int) KnownEvents.DateOfEntry,
            (int) KnownEvents.DateOfLastChange
        };

        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IInheritance _inheritance;

        public WorkflowPermissionHelper(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider, IInheritance inheritance)
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

        public bool CanEditEvent(Criteria criteria, int eventId, out bool isEditBlockedByDescendants, out bool isNonConfigurableEvent)
        {
            isEditBlockedByDescendants = false;
            isNonConfigurableEvent = IsSystemEvent(eventId);

            if (isNonConfigurableEvent)
            {
                return false;
            }

            return CanEdit(criteria, out isEditBlockedByDescendants);
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
            return _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected);
        }

        public void EnsureEditEventControlPermission(int criteriaId, int eventId)
        {
            if (IsSystemEvent(eventId))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }

            var criteria = _dbContext.Set<Criteria>().WhereWorkflowCriteria().Single(_ => _.Id == criteriaId);
            if (!CanEdit(criteria))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }
        }

        public void EnsureEditPermission(int criteriaId)
        {
            var criteria = _dbContext.Set<Criteria>().WhereWorkflowCriteria().Single(_ => _.Id == criteriaId);
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

        bool IsSystemEvent(int eventId)
        {
            return _systemEvents.Contains(eventId);
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

        public bool CanCreateNegativeWorkflow()
        {
            return _taskSecurityProvider.HasAccessTo(ApplicationTask.CreateNegativeWorkflowRules);
        }

        bool IsEditBlockedByDescendants(Criteria criteria, bool hasProtectedDescendants)
        {
            var canEditProtected = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected);
            var canEditNonProtected = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules);

            // Special scenario DR-24124
            return canEditNonProtected && !canEditProtected && !criteria.IsProtected && hasProtectedDescendants;
        }

        bool CanEditNonProtected()
        {
            return _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules);
        }
    }
}