using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IWorkflowSearch
    {
        IEnumerable<WorkflowSearchListItem> Search(SearchCriteria filter);
        IEnumerable<WorkflowSearchListItem> Search(int[] ids);
        IEnumerable<WorkflowEventReferenceListItem> SearchForEventReferencedInCriteria(int criteriaId, int eventId);
    }

    public class WorkflowSearch : IWorkflowSearch
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public WorkflowSearch(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (securityContext == null) throw new ArgumentNullException("securityContext");
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");

            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public IEnumerable<WorkflowSearchListItem> Search(SearchCriteria filter)
        {
            return _dbContext.WorkflowSearch(_securityContext.User.Id,
                                             _preferredCultureResolver.Resolve(),
                                             filter);
        }

        public IEnumerable<WorkflowSearchListItem> Search(int[] ids)
        {
            return _dbContext.WorkflowSearchById(_securityContext.User.Id,
                                                 _preferredCultureResolver.Resolve(),
                                                 ids);
        }

        public IEnumerable<WorkflowEventReferenceListItem> SearchForEventReferencedInCriteria(int criteriaId, int eventId)
        {
            return _dbContext.WorkflowEventReferenceSearch(criteriaId, eventId);
        }
    }
}