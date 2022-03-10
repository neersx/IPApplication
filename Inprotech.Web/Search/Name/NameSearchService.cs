using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Names.Search;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using System.Linq;
using System.Xml.Linq;

namespace Inprotech.Web.Search.Name
{
    public interface INameSearchService
    {
        void UpdateFilterForBulkOperation<T>(SearchExportParams<NameSearchRequestFilter<T>> searchExportParams) where T : NameSearchRequestBase, new();
    }

    public class NameSearchService : INameSearchService
    {
        readonly IDbContext _dbContext;
        readonly IXmlFilterCriteriaBuilderResolver _filterCriteriaBuilderResolver;
        readonly IFilterableColumnsMapResolver _filterableColumnsMapResolver;

        public NameSearchService(IDbContext dbContext, IXmlFilterCriteriaBuilderResolver filterCriteriaBuilderResolver, IFilterableColumnsMapResolver filterableColumnsMapResolver)
        {
            _dbContext = dbContext;
            _filterCriteriaBuilderResolver = filterCriteriaBuilderResolver;
            _filterableColumnsMapResolver = filterableColumnsMapResolver;
        }

        public void UpdateFilterForBulkOperation<T>(SearchExportParams<NameSearchRequestFilter<T>> searchExportParams) where T : NameSearchRequestBase, new()
        {
            
            if (searchExportParams.QueryKey.HasValue && searchExportParams.Criteria.SearchRequest?.First().NameKeys == null)
            {
                string xmlFilterCriteria;
                if (!string.IsNullOrEmpty(searchExportParams.Criteria.XmlSearchRequest))
                {
                    xmlFilterCriteria = searchExportParams.Criteria.XmlSearchRequest;
                }
                else if (searchExportParams.Criteria.SearchRequest != null && searchExportParams.Criteria.SearchRequest.Any())
                {
                    var filterableColumnsMap = _filterableColumnsMapResolver.Resolve(searchExportParams.QueryContext);
                   
                    xmlFilterCriteria = _filterCriteriaBuilderResolver.Resolve(searchExportParams.QueryContext)
                                                                      .Build(searchExportParams.Criteria, new CommonQueryParameters(), filterableColumnsMap);
                }
                else
                {
                    var query = _dbContext.Set<Query>().Single(_ => _.Id == searchExportParams.QueryKey);
                    xmlFilterCriteria = _dbContext.Set<QueryFilter>().Single(_ => _.Id == query.FilterId).XmlFilterCriteria;
                }

                xmlFilterCriteria = AddStepToFilterCases(searchExportParams.DeselectedIds, xmlFilterCriteria);

                searchExportParams.Criteria.XmlSearchRequest = xmlFilterCriteria;

            }
            else if (searchExportParams.DeselectedIds != null && searchExportParams.DeselectedIds.Length > 0)
            {
                if (!string.IsNullOrWhiteSpace(searchExportParams.Criteria.XmlSearchRequest))
                {
                    searchExportParams.Criteria.XmlSearchRequest = AddStepToFilterCases(searchExportParams.DeselectedIds, searchExportParams.Criteria.XmlSearchRequest);
                }
                else
                {
                    var request = searchExportParams.Criteria.SearchRequest.ToList();
                    request.Add(new T
                    {
                        Id = request.Count + 1,
                        Operator = "AND",
                        IsCeased = false,
                        IsCurrent = true,
                        NameKeys = new SearchElement
                        {
                            Value = string.Join(",", searchExportParams.DeselectedIds),
                            Operator = (short)CollectionExtensions.FilterOperator.NotIn,
                        }
                    });
                    searchExportParams.Criteria.SearchRequest = request;
                    searchExportParams.ForceConstructXmlCriteria = true;
                }
            }
        }

        string AddStepToFilterCases(int[] deselectedIds, string xmlFilterCriteria)
        {
            if (deselectedIds == null || deselectedIds.Length <= 0) return xmlFilterCriteria;

            var xmlCriteria = XElement.Parse(xmlFilterCriteria);

            var filterCriteriaGroup = xmlCriteria.DescendantsAndSelf("FilterCriteriaGroup").First();

            var stepCount = xmlCriteria.DescendantsAndSelf("FilterCriteria").Count();

            var newStep = new XElement("FilterCriteria", new XAttribute("ID", (++stepCount).ToString()), new XAttribute("BooleanOperator", "AND"),
                                       new XElement("IsCeased", "0"),
                                       new XElement("IsLead", "0"),
                                       new XElement("IsCurrent", "1"),
                                       new XElement("NameKeys", new XAttribute("Operator", (short)CollectionExtensions.FilterOperator.NotIn), deselectedIds.Select(_ => new XElement("NameKey", _))));

            filterCriteriaGroup.Add(newStep);
            xmlFilterCriteria = xmlCriteria.ToString();

            return xmlFilterCriteria;
        }
    }
}