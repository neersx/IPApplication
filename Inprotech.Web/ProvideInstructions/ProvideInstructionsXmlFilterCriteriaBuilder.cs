using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Queries;
using System.Xml.Linq;

namespace Inprotech.Web.ProvideInstructions
{
    public class ProvideInstructionsXmlFilterCriteriaBuilder : IXmlFilterCriteriaBuilder
    {
        readonly IProvideInstructionFilterCriteriaBuilder _builder;

        public ProvideInstructionsXmlFilterCriteriaBuilder(IProvideInstructionFilterCriteriaBuilder builder)
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
