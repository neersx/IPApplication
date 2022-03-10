using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.Reminders.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.TaskPlanner
{
    public class TaskPlannerXmlFilterCriteriaBuilder : IXmlFilterCriteriaBuilder
    {
        readonly ITaskPlannerFilterCriteriaBuilder _builder;

        public TaskPlannerXmlFilterCriteriaBuilder(ITaskPlannerFilterCriteriaBuilder builder)
        {
            _builder = builder;
        }

        public string Build<T>(T req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter
        {
            return _builder.Build(req, queryParameters, filterableColumnsMap).ToString(SaveOptions.DisableFormatting);
        }

        public string Build<T>(T req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter
        {
            return _builder.Build(req, xmlFilterCriteria, queryParameters, filterableColumnsMap).ToString(SaveOptions.DisableFormatting);
        }
    }
}
