using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.ProvideInstructions
{
    public class ProvideInstructionsFilterableColumnsMap : IFilterableColumnsMap
    {
        public ProvideInstructionsFilterableColumnsMap()
        {
            Columns = new ReadOnlyDictionary<string, string>(new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase));

            XmlCriteriaFields = new ReadOnlyDictionary<string, string>(new Dictionary<string, string>(StringComparer.CurrentCultureIgnoreCase));
        }

        public IReadOnlyDictionary<string, string> Columns { get; }

        public IReadOnlyDictionary<string, string> XmlCriteriaFields { get; }
    }
}
