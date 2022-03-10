using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.Case
{
    public class FilterableColumnsMap : IFilterableColumnsMap
    {
        public FilterableColumnsMap()
        {
            Columns = new ReadOnlyDictionary<string, string>(new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase)
            {
                {"CountryName", "CountryCode"},
                {"CaseTypeDescription", "CaseTypeKey"},
                {"PropertyTypeDescription", "PropertyTypeKey"},
                {"StatusDescription", "StatusKey"},
                {"StatusExternalDescription", "StatusKey"},
                {"CaseReference", "CaseKey"}
            });

            XmlCriteriaFields = new ReadOnlyDictionary<string, string>(new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase)
            {
                {"CountryCode", "CountryCodes"},
                {"CaseTypeKey", "CaseTypeKey"},
                {"PropertyTypeKey", "PropertyTypeKey"},
                {"StatusKey", "StatusKey"},
                {"CaseKey", "CaseKeys"}
            });
        }

        public IReadOnlyDictionary<string, string> Columns { get; }

        public IReadOnlyDictionary<string, string> XmlCriteriaFields { get; }
    }
}