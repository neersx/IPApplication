using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Ede.DataMapping;

namespace Inprotech.Web.Configuration.Ede.DataMapping.Mappings
{
    public interface IMappingHandler
    {
        IEnumerable<Mapping> FetchBy(int? systemId, int structure);

        bool TryValidate(DataSource dataSource, MapStructure mapStructure, Mapping mapping, out IEnumerable<string> errors);

        Type MappingType { get; }
    }
}