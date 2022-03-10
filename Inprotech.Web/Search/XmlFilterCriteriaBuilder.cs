using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search
{
    public interface IXmlFilterCriteriaBuilderResolver
    {
        IXmlFilterCriteriaBuilder Resolve(QueryContext queryContext);
    }

    public class XmlFilterCriteriaBuilderResolver : IXmlFilterCriteriaBuilderResolver
    {
        readonly IIndex<QueryContext, IXmlFilterCriteriaBuilder> _builderFactory;

        public XmlFilterCriteriaBuilderResolver(IIndex<QueryContext, IXmlFilterCriteriaBuilder> builderFactory)
        {
            _builderFactory = builderFactory;
        }

        public IXmlFilterCriteriaBuilder Resolve(QueryContext queryContext)
        {
            return _builderFactory[queryContext];
        }
    }

    public interface IXmlFilterCriteriaBuilder
    {
        string Build<T>(T req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter;
        
        string Build<T>(T req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap) where T : SearchRequestFilter;
    }
}