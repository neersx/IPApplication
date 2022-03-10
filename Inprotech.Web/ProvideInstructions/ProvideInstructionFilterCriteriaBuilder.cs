using System;
using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Serialization;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.ProvideInstructions
{
    public interface IProvideInstructionFilterCriteriaBuilder
    {
        XElement Build(SearchRequestFilter req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);

        XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap);
    }

    public class ProvideInstructionFilterCriteriaBuilder : IProvideInstructionFilterCriteriaBuilder
    {
        readonly ISerializeXml _xmlSerializer;
        public ProvideInstructionFilterCriteriaBuilder(ISerializeXml xmlSerializer)
        {
            _xmlSerializer = xmlSerializer;
        }

        public XElement Build(SearchRequestFilter req, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            if (req == null) throw new ArgumentNullException(nameof(req));
            if (filterableColumnsMap == null) throw new ArgumentNullException(nameof(filterableColumnsMap));

            return BuildFromSearchRequest(((ProvideInstructionsRequestFilter)req).ColumnFilterCriteria, queryParameters,filterableColumnsMap);
        }
            
        public XElement Build(SearchRequestFilter req, string xmlFilterCriteria, CommonQueryParameters queryParameters, IFilterableColumnsMap filterableColumnsMap)
        {
            throw new System.NotImplementedException();
        }

        XElement BuildFromSearchRequest(ColumnFilterCriteria columnFilterCriteria, CommonQueryParameters queryParameters,IFilterableColumnsMap filterableColumnsMap)
        {
            var criteria = new XElement("csw_ListCase",  XElement.Parse(_xmlSerializer.Serialize(columnFilterCriteria)));
           
            return criteria;
        }

    }
}
    