using System;
using System.Xml.Linq;

namespace Inprotech.Web.Lists
{
    public class FilterCriteriaBuilder
    {
        string _query;
        bool _hasGroup;
        string _storedProcedureName;
        string _nameType;
        
        public XElement Build()
        {
            if(_storedProcedureName == null) throw new Exception("stored procedure name must be specified");
            
            var sproc = new XElement(_storedProcedureName);
            var group = new XElement("FilterCriteriaGroup");
            var criteria = new XElement("FilterCriteria");
            
            if(IsCurrent)
                criteria.Add(new XElement("IsCurrent", 1));

            if(IsStaff)
                criteria.Add(new XElement("EntityFlags", new XElement("IsStaff", 1)));

            if(_nameType != null)
                criteria.Add(new XElement("SuitableForNameTypeKey", _nameType));

            criteria.Add(new XElement("PickListKey"));

            criteria.Add(new XElement("PickListSearch", _query));
            
            if(_hasGroup)
            {
                sproc.Add(group);
                group.Add(criteria);
            }
            else
            {
                sproc.Add(criteria);
            }

            return new XElement("Search", new XElement("Filtering", sproc));
        }

        public FilterCriteriaBuilder WithSearch(string query)
        {
            _query = query;

            return this;
        }

        public FilterCriteriaBuilder WithGroup()
        {
            _hasGroup = true;

            return this;
        }

        public FilterCriteriaBuilder WithStoredProcedureName(string storedProcedureName)
        {
            _storedProcedureName = storedProcedureName;

            return this;
        }

        public bool IsStaff { get; set; }

        public bool IsCurrent { get; set; }

        public FilterCriteriaBuilder WithNameType(string nameType)
        {
            _nameType = nameType;

            return this;
        }
    }
}