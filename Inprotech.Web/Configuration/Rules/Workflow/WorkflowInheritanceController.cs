using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Xml.Linq;
using System.Xml.XPath;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
    [RoutePrefix("api/configuration/rules/workflows")]
    public class WorkflowInheritanceController : ApiController
    {
        bool _firstNodeSet;
        readonly IWorkflowInheritanceService _workflowInheritanceService;
        readonly IWorkflowPermissionHelper _permissionHelper;
        readonly IDbContext _dbContext;
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;
        readonly IWorkflowEntryInheritanceService _workflowEntryInheritanceService;
        readonly IWorkflowMaintenanceService _workflowMaintenanceService;

        public WorkflowInheritanceController(IWorkflowInheritanceService workflowInheritanceService, IWorkflowPermissionHelper permissionHelper, IDbContext dbContext, 
            IWorkflowEventInheritanceService workflowEventInheritanceService, IWorkflowEntryInheritanceService workflowEntryInheritanceService, 
            IWorkflowMaintenanceService workflowMaintenanceService)
        {
            _workflowInheritanceService = workflowInheritanceService;
            _permissionHelper = permissionHelper;
            _dbContext = dbContext;
            _workflowEventInheritanceService = workflowEventInheritanceService;
            _workflowEntryInheritanceService = workflowEntryInheritanceService;
            _workflowMaintenanceService = workflowMaintenanceService;
        }

        [HttpGet]
        [Route("inheritance")]
        public SearchResult Search(string criteriaIds, int? selectedNode = null)
        {
            if (criteriaIds == null) throw new ArgumentNullException(nameof(criteriaIds));
            var parsedIds = criteriaIds.Split(',').Select(int.Parse).ToArray();

            var inheritanceXmlStr = _workflowInheritanceService.GetInheritanceTreeXml(parsedIds);
            var xml = XElement.Parse(inheritanceXmlStr);

            if (selectedNode != null)
            {
                var theSelectedNode = xml.XPathSelectElement($"//CRITERIANO[text()=\"{selectedNode}\"]");
                if (theSelectedNode == null)
                {
                    var selectedNodeTree = _workflowInheritanceService.GetInheritanceTreeXml(new [] {selectedNode.Value});
                    var selectedNodeXml = XElement.Parse(selectedNodeTree);
                    xml.AddFirst(selectedNodeXml.FirstNode);
                }
            }

            int totalCount;
            var trees = ParseTrees(xml, parsedIds, out totalCount).ToArray();

            return new SearchResult
            {
                Trees = trees,
                TotalCount = totalCount,
                CanEditProtected = _permissionHelper.CanEditProtected(),
                HasOffices = _dbContext.Set<Office>().Any()
            };
        }

        [HttpDelete]
        [Route("{criteriaId:int}/inheritance")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public void BreakInheritance(int criteriaId)
        {
            _permissionHelper.EnsureEditPermission(criteriaId);

            using (var transaction = _dbContext.BeginTransaction())
            {
                _workflowInheritanceService.BreakInheritance(criteriaId);
                transaction.Complete();
            }
        }

        public class SearchResult
        {
            public IEnumerable<Node> Trees { get; set; }
            public int TotalCount { get; set; }
            public bool CanEditProtected { get; set; }
            public bool HasOffices { get; set; }
        }

        [HttpPut]
        [Route("{criteriaId:int}/inheritance")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic ChangeParentInheritance(int criteriaId, ChangeParentInheritanceParams changeParentInheritanceParams)
        {
            if (changeParentInheritanceParams.NewParent == null) throw new ArgumentNullException(nameof(changeParentInheritanceParams.NewParent));

            if (changeParentInheritanceParams.NewParent != null && !CanMoveChildToParent(criteriaId, changeParentInheritanceParams.NewParent.Value))
                throw new HttpResponseException(HttpStatusCode.InternalServerError);

            _permissionHelper.EnsureEditPermission(criteriaId);

            var newParentCriteriaId = changeParentInheritanceParams.NewParent.Value;
            var replaceCommonRules = changeParentInheritanceParams.ReplaceCommonRules;

            var parentEventRules = _dbContext.Set<ValidEvent>()
                                            .Include("Event")
                                            .Include("DueDateCalcs")
                                            .Include("DatesLogic")
                                            .Include("RelatedEvents")
                                            .Include("Reminders")
                                            .Include("NameTypeMaps")
                                            .Include("RequiredEvents")
                                            .Where(_ => _.CriteriaId == newParentCriteriaId)
                                            .ToArray();

            var parentEntries = _dbContext.Set<DataEntryTask>()
                .Include(_ => _.AvailableEvents)
                .Include(_ => _.DocumentRequirements)
                .Include(_ => _.GroupsAllowed)
                .Include(_ => _.UsersAllowed)
                .Include(_ => _.RolesAllowed)
                .Where(_ => _.CriteriaId == newParentCriteriaId).ToArray();

            var duplicateEntries = string.Empty;
            using (var inheritScope = _dbContext.BeginTransaction())
            {
                _workflowInheritanceService.BreakInheritance(criteriaId);

                var criteria = _dbContext.Set<Criteria>()
                                         .Include(_ => _.DataEntryTasks)
                                         .Include(_ => _.ValidEvents)
                                         .Single(c => c.Id == criteriaId);

                criteria.ParentCriteriaId = newParentCriteriaId;
                _dbContext.Set<Inherits>().Add(new Inherits(criteriaId, newParentCriteriaId));

                try
                {
                    var inheritedParentRules = _workflowEventInheritanceService.InheritNewEventRules(criteria, parentEventRules, replaceCommonRules).ToArray();
                    var inheritedParentEntries = _workflowEntryInheritanceService.InheritNewEntries(criteria, parentEntries, replaceCommonRules).ToArray();

                    if (inheritedParentRules.Any() || inheritedParentEntries.Any())
                        _workflowInheritanceService.PushDownInheritanceTree(criteria.Id, inheritedParentRules, inheritedParentEntries, replaceCommonRules);

                    inheritScope.Complete();
                }
                catch (DuplicateEntryDescriptionException ex)
                {
                    duplicateEntries = ex.Message;
                }
            }

            return new
            {
                UsedByCase = _workflowMaintenanceService.CheckCriteriaUsedByLiveCases(criteriaId),
                HasDuplicateEntries = !string.IsNullOrEmpty(duplicateEntries),
                DuplicateEntries = duplicateEntries
            };
        }

        bool CanMoveChildToParent(int criteriaId, int newParentCriteriaId)
        {
            var criterias = _dbContext.Set<Criteria>().Where(_ => _.Id == criteriaId || _.Id == newParentCriteriaId);
            var parent = criterias.Single(_ => _.Id == newParentCriteriaId);
            var criteria = criterias.Single(_ => _.Id == criteriaId);

            return !criteria.IsProtected || parent.IsProtected;
        }

        public class ChangeParentInheritanceParams
        {
            public int? NewParent { get; set; }
            public bool ReplaceCommonRules { get; set; }
        }

        public class Node
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public bool IsProtected { get; set; }
            public bool IsInSearch { get; set; }
            public bool IsFirstFromSearch { get; set; }
            public IEnumerable<Node> Items { get; set; }
            [JsonIgnore]
            public int TotalCount { get; set; }
            public bool HasProtectedChildren { get; set; }
        }

        internal IEnumerable<Node> ParseTrees(XElement element, int[] criteriaIds, out int totalCount)
        {
            var trees = new List<Node>();

            totalCount = 0;
            foreach (var x in element.Elements("CRITERIA"))
            {
                var tree = ParseTree(x, criteriaIds);
                trees.Add(tree);
                totalCount += tree.TotalCount;
            }

            return trees;
        }

        internal Node ParseTree(XElement element, int[] criteriaIds)
        {
            var id = int.Parse(element.Element("CRITERIANO").Value);
            var name = element.Element("DESCRIPTION")?.Value;
            var isProtected = element.Element("ISUSERDEFINED")?.Value == "0";
            var children = new List<Node>();
            var totalCount = 1;
            
            // this has to be done before we go down to the children
            var inSearch = criteriaIds.Contains(id);
            var isFirstNode = false;
            if (!_firstNodeSet && inSearch)
            {
                _firstNodeSet = true;
                isFirstNode = true;
            }

            var childCriteria = element.Element("CHILDCRITERIA")?.Elements("CRITERIA");
            if (childCriteria != null)
            {
                foreach (var x in childCriteria)
                {
                    var node = ParseTree(x, criteriaIds);
                    children.Add(node);
                    totalCount += node.TotalCount;
                }
            }

            return new Node
            {
                Id = id,
                IsProtected = isProtected,
                Name = name,
                IsInSearch = inSearch,
                IsFirstFromSearch = isFirstNode,
                TotalCount = totalCount,
                Items = children.Any() ? children : null,
                HasProtectedChildren = children.Any(_ => _.IsProtected || _.HasProtectedChildren)
            };
        }
    }
}
