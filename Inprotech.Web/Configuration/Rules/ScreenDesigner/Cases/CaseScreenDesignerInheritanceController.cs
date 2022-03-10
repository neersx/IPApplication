using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml.Linq;
using System.Xml.XPath;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

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
    public class CaseScreenDesignerInheritanceController : ApiController
    {
        bool _firstNodeSet;
        readonly ICaseScreenDesignerPermissionHelper _permissionHelper;
        readonly IDbContext _dbContext;
        readonly ICaseScreenDesignerInheritanceService _caseScreenDesignerInheritanceService;
        public CaseScreenDesignerInheritanceController(ICaseScreenDesignerPermissionHelper permissionHelper, IDbContext dbContext, ICaseScreenDesignerInheritanceService caseScreenDesignerInheritanceService)
        {
            _permissionHelper = permissionHelper;
            _dbContext = dbContext;
            _caseScreenDesignerInheritanceService = caseScreenDesignerInheritanceService;
        }

        [HttpGet]
        [Route("inheritance")]
        public SearchResult Search(string criteriaIds, int? selectedNode = null)
        {
            if (criteriaIds == null) throw new ArgumentNullException(nameof(criteriaIds));
            var parsedIds = criteriaIds.Split(',').Select(int.Parse).ToArray();

            var inheritanceXmlStr = _caseScreenDesignerInheritanceService.GetInheritanceTreeXml(parsedIds);
            var xml = XElement.Parse(inheritanceXmlStr);

            if (selectedNode != null)
            {
                var theSelectedNode = xml.XPathSelectElement($"//CRITERIANO[text()=\"{selectedNode}\"]");
                if (theSelectedNode == null)
                {
                    var selectedNodeTree = _caseScreenDesignerInheritanceService.GetInheritanceTreeXml(new[] { selectedNode.Value });
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

        public class SearchResult
        {
            public IEnumerable<Node> Trees { get; set; }
            public int TotalCount { get; set; }
            public bool CanEditProtected { get; set; }
            public bool HasOffices { get; set; }
        }
    }
}
